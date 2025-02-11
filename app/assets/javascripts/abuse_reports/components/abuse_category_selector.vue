<script>
import { GlButton, GlDrawer, GlForm, GlFormGroup, GlFormRadioGroup } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import csrf from '~/lib/utils/csrf';

export default {
  name: 'AbuseCategorySelector',
  csrf,
  components: {
    GlButton,
    GlDrawer,
    GlForm,
    GlFormGroup,
    GlFormRadioGroup,
  },
  inject: ['formSubmitPath', 'userId', 'reportedFromUrl'],
  props: {
    showDrawer: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    title: __('Report abuse to administrator'),
    close: __('Close'),
    label: s__('ReportAbuse|Why are you reporting this user?'),
    next: __('Next'),
  },
  categoryOptions: [
    { value: 'spam', text: s__("ReportAbuse|They're posting spam.") },
    { value: 'offensive', text: s__("ReportAbuse|They're being offsensive or abusive.") },
    { value: 'phishing', text: s__("ReportAbuse|They're phising.") },
    { value: 'crypto', text: s__("ReportAbuse|They're crypto mining.") },
    {
      value: 'credentials',
      text: s__("ReportAbuse|They're posting personal information or credentials."),
    },
    { value: 'copyright', text: s__("ReportAbuse|They're violating a copyright or trademark.") },
    { value: 'malware', text: s__("ReportAbuse|They're posting malware.") },
    { value: 'other', text: s__('ReportAbuse|Something else.') },
  ],
  data() {
    return {
      selected: '',
    };
  },
  computed: {
    drawerOffsetTop() {
      const wrapperEl = document.querySelector('.content-wrapper');
      return wrapperEl ? `${wrapperEl.offsetTop}px` : '';
    },
  },
  methods: {
    closeDrawer() {
      this.$emit('close-drawer');
    },
  },
};
</script>
<template>
  <gl-drawer :header-height="drawerOffsetTop" :open="showDrawer" @close="closeDrawer">
    <template #title>
      <h2
        class="gl-font-size-h2 gl-mt-0 gl-mb-0 gl-line-height-24"
        data-testid="category-drawer-title"
      >
        {{ $options.i18n.title }}
      </h2>
    </template>
    <template #default>
      <gl-form :action="formSubmitPath" method="post" class="gl-text-left">
        <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />

        <input type="hidden" name="user_id" :value="userId" data-testid="input-user-id" />
        <input type="hidden" name="ref_url" :value="reportedFromUrl" data-testid="input-referer" />

        <gl-form-group :label="$options.i18n.label">
          <gl-form-radio-group
            v-model="selected"
            :options="$options.categoryOptions"
            name="abuse_report[category]"
            required
          />
        </gl-form-group>

        <gl-button type="submit" variant="confirm" data-testid="submit-form-button">
          {{ $options.i18n.next }}
        </gl-button>
      </gl-form>
    </template>
  </gl-drawer>
</template>
