<script>
import {
  GlAlert,
  GlButton,
  GlIcon,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlPagination,
  GlSprintf,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import { HTTP_STATUS_PAYLOAD_TOO_LARGE } from '~/lib/utils/http_status';
import { __, s__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlLoadingIcon,
    GlModal,
    GlPagination,
    GlSprintf,
    GlTable,
    TimeagoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['projectId', 'admin', 'fileSizeLimit'],
  DEFAULT_PER_PAGE,
  i18n: {
    deleteLabel: __('Delete File'),
    uploadLabel: __('Upload File'),
    uploadingLabel: __('Uploading...'),
    noFilesMessage: __('There are no secure files yet.'),
    pagination: {
      next: __('Next'),
      prev: __('Prev'),
    },
    uploadErrorMessages: {
      duplicate: __('A file with this name already exists.'),
      tooLarge: __('File too large. Secure Files must be less than %{limit} MB.'),
    },
    deleteModalTitle: s__('SecureFiles|Delete %{name}?'),
    deleteModalMessage: s__(
      'SecureFiles|Secure File %{name} will be permanently deleted. Are you sure?',
    ),
    deleteModalButton: s__('SecureFiles|Delete secure file'),
  },
  deleteModalId: 'deleteModalId',
  data() {
    return {
      page: 1,
      totalItems: 0,
      loading: false,
      uploading: false,
      error: false,
      errorMessage: null,
      projectSecureFiles: [],
      deleteModalFileId: null,
      deleteModalFileName: null,
    };
  },
  fields: [
    {
      key: 'name',
      label: __('File name'),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'created_at',
      label: __('Uploaded date'),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-text-right gl-vertical-align-middle!',
    },
  ],
  computed: {
    fields() {
      return this.$options.fields;
    },
  },
  watch: {
    page(newPage) {
      this.getProjectSecureFiles(newPage);
    },
  },
  created() {
    this.getProjectSecureFiles();
  },
  methods: {
    async deleteSecureFile(secureFileId) {
      this.loading = true;
      this.error = false;
      try {
        await Api.deleteProjectSecureFile(this.projectId, secureFileId);
        this.getProjectSecureFiles();

        this.track('delete_secure_file');
      } catch (error) {
        Sentry.captureException(error);
        this.error = true;
        this.errorMessage = error;
      }
    },
    async getProjectSecureFiles(page) {
      this.loading = true;
      const response = await Api.projectSecureFiles(this.projectId, { page });

      this.totalItems = parseInt(response.headers?.['x-total'], 10) || 0;

      this.projectSecureFiles = response.data;

      this.loading = false;
      this.uploading = false;
      this.track('render_secure_files_list');
    },
    async uploadSecureFile() {
      this.error = null;
      this.uploading = true;
      const [file] = this.$refs.fileUpload.files;
      try {
        await Api.uploadProjectSecureFile(this.projectId, this.uploadFormData(file));
        this.getProjectSecureFiles();
        this.track('upload_secure_file');
      } catch (error) {
        this.error = true;
        this.errorMessage = this.formattedErrorMessage(error);
        this.uploading = false;
      }
    },
    formattedErrorMessage(error) {
      let message = '';
      if (error?.response?.data?.message?.name) {
        message = this.$options.i18n.uploadErrorMessages.duplicate;
      } else if (error.response.status === HTTP_STATUS_PAYLOAD_TOO_LARGE) {
        message = sprintf(this.$options.i18n.uploadErrorMessages.tooLarge, {
          limit: this.fileSizeLimit,
        });
      } else {
        Sentry.captureException(error);
        message = error;
      }
      return message;
    },
    loadFileSelector() {
      this.$refs.fileUpload.click();
    },
    setDeleteModalData(secureFile) {
      this.deleteModalFileId = secureFile.id;
      this.deleteModalFileName = secureFile.name;
    },
    uploadFormData(file) {
      const formData = new FormData();
      formData.append('name', file.name);
      formData.append('file', file);

      return formData;
    },
  },
};
</script>

<template>
  <div>
    <div class="ci-secure-files-table">
      <gl-alert v-if="error" variant="danger" class="gl-mt-6" @dismiss="error = null">
        {{ errorMessage }}
      </gl-alert>

      <gl-table
        :busy="loading"
        :fields="fields"
        :items="projectSecureFiles"
        tbody-tr-class="js-ci-secure-files-row"
        data-qa-selector="ci_secure_files_table_content"
        sort-by="key"
        sort-direction="asc"
        stacked="lg"
        table-class="text-secondary"
        show-empty
        sort-icon-left
        no-sort-reset
        :empty-text="$options.i18n.noFilesMessage"
      >
        <template #table-busy>
          <gl-loading-icon size="lg" class="gl-my-5" />
        </template>

        <template #cell(name)="{ item }">
          {{ item.name }}
        </template>

        <template #cell(created_at)="{ item }">
          <timeago-tooltip :time="item.created_at" />
        </template>

        <template #cell(actions)="{ item }">
          <gl-button
            v-if="admin"
            v-gl-modal="$options.deleteModalId"
            v-gl-tooltip.hover.top="$options.i18n.deleteLabel"
            category="secondary"
            variant="danger"
            icon="remove"
            :aria-label="$options.i18n.deleteLabel"
            data-testid="delete-button"
            @click="setDeleteModalData(item)"
          />
        </template>
      </gl-table>
    </div>

    <div class="gl-display-flex gl-mt-5">
      <gl-button v-if="admin" variant="confirm" @click="loadFileSelector">
        <span v-if="uploading">
          <gl-loading-icon class="gl-my-5" inline />
          {{ $options.i18n.uploadingLabel }}
        </span>
        <span v-else>
          <gl-icon name="upload" class="gl-mr-2" /> {{ $options.i18n.uploadLabel }}
        </span>
      </gl-button>
      <input
        id="file-upload"
        ref="fileUpload"
        type="file"
        class="hidden"
        data-qa-selector="file_upload_field"
        @change="uploadSecureFile"
      />
    </div>

    <gl-pagination
      v-if="!loading"
      v-model="page"
      :per-page="$options.DEFAULT_PER_PAGE"
      :total-items="totalItems"
      :next-text="$options.i18n.pagination.next"
      :prev-text="$options.i18n.pagination.prev"
      align="center"
    />

    <gl-modal
      :ref="$options.deleteModalId"
      :modal-id="$options.deleteModalId"
      title-tag="h4"
      category="primary"
      :ok-title="$options.i18n.deleteModalButton"
      ok-variant="danger"
      @ok="deleteSecureFile(deleteModalFileId)"
    >
      <template #modal-title>
        <gl-sprintf :message="$options.i18n.deleteModalTitle">
          <template #name>{{ deleteModalFileName }}</template>
        </gl-sprintf>
      </template>

      <gl-sprintf :message="$options.i18n.deleteModalMessage">
        <template #name>{{ deleteModalFileName }}</template>
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
