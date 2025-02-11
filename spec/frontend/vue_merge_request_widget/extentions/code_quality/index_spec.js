import MockAdapter from 'axios-mock-adapter';
import { GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import codeQualityExtension from '~/vue_merge_request_widget/extensions/code_quality';
import httpStatusCodes, { HTTP_STATUS_NO_CONTENT } from '~/lib/utils/http_status';
import { i18n } from '~/vue_merge_request_widget/extensions/code_quality/constants';
import {
  codeQualityResponseNewErrors,
  codeQualityResponseResolvedAndNewErrors,
  codeQualityResponseNoErrors,
} from './mock_data';

describe('Code Quality extension', () => {
  let wrapper;
  let mock;

  registerExtension(codeQualityExtension);

  const endpoint = '/root/repo/-/merge_requests/4/accessibility_reports.json';

  const mockApi = (statusCode, data) => {
    mock.onGet(endpoint).reply(statusCode, data);
  };

  const findToggleCollapsedButton = () => wrapper.findByTestId('toggle-button');
  const findAllExtensionListItems = () => wrapper.findAllByTestId('extension-list-item');

  const createComponent = () => {
    wrapper = mountExtended(extensionsContainer, {
      propsData: {
        mr: {
          codeQuality: endpoint,
          blobPath: {
            head_path: 'example/path',
            base_path: 'example/path',
          },
        },
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('summary', () => {
    it('displays loading text', () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseNewErrors);

      createComponent();

      expect(wrapper.text()).toBe(i18n.loading);
    });

    it('with a 204 response, continues to display loading state', async () => {
      mockApi(HTTP_STATUS_NO_CONTENT, '');
      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(i18n.loading);
    });

    it('displays failed loading text', async () => {
      mockApi(httpStatusCodes.INTERNAL_SERVER_ERROR);

      createComponent();

      await waitForPromises();
      expect(wrapper.text()).toBe(i18n.error);
    });

    it('displays correct single Report', async () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseNewErrors);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(
        i18n.degradedCopy(i18n.singularReport(codeQualityResponseNewErrors.new_errors)),
      );
    });

    it('displays quality improvement and degradation', async () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseResolvedAndNewErrors);

      createComponent();
      await waitForPromises();

      // replacing strong tags because they will not be found in the rendered text
      expect(wrapper.text()).toBe(
        i18n
          .improvementAndDegradationCopy(
            i18n.pluralReport(codeQualityResponseResolvedAndNewErrors.resolved_errors),
            i18n.pluralReport(codeQualityResponseResolvedAndNewErrors.new_errors),
          )
          .replace(/%{strong_start}/g, '')
          .replace(/%{strong_end}/g, ''),
      );
    });

    it('displays no detected errors', async () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseNoErrors);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(i18n.noChanges);
    });
  });

  describe('expanded data', () => {
    beforeEach(async () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseResolvedAndNewErrors);

      createComponent();

      await waitForPromises();

      findToggleCollapsedButton().trigger('click');

      await waitForPromises();
    });

    it('displays all report list items in viewport', async () => {
      expect(findAllExtensionListItems()).toHaveLength(2);
    });

    it('displays report list item formatted', () => {
      const text = {
        newError: trimText(findAllExtensionListItems().at(0).text().replace(/\s+/g, ' ').trim()),
        resolvedError: findAllExtensionListItems().at(1).text().replace(/\s+/g, ' ').trim(),
      };

      expect(text.newError).toContain(
        "Minor - Parsing error: 'return' outside of function in index.js:12",
      );
      expect(text.resolvedError).toContain(
        "Minor - Parsing error: 'return' outside of function Fixed in index.js:12",
      );
    });

    it('adds fixed indicator (badge) when error is resolved', () => {
      expect(findAllExtensionListItems().at(1).findComponent(GlBadge).exists()).toBe(true);
      expect(findAllExtensionListItems().at(1).findComponent(GlBadge).text()).toEqual(i18n.fixed);
    });

    it('should not add fixed indicator (badge) when error is new', () => {
      expect(findAllExtensionListItems().at(0).findComponent(GlBadge).exists()).toBe(false);
    });
  });
});
