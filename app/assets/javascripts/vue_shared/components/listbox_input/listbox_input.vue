<script>
import { GlFormGroup, GlListbox } from '@gitlab/ui';
import { __ } from '~/locale';

const MIN_ITEMS_COUNT_FOR_SEARCHING = 10;

export default {
  i18n: {
    noResultsText: __('No results found'),
  },
  components: {
    GlFormGroup,
    GlListbox,
  },
  model: GlListbox.model,
  props: {
    label: {
      type: String,
      required: false,
      default: '',
    },
    name: {
      type: String,
      required: true,
    },
    defaultToggleText: {
      type: String,
      required: false,
      default: '',
    },
    selected: {
      type: String,
      required: false,
      default: null,
    },
    items: {
      type: GlListbox.props.items.type,
      required: true,
    },
  },
  data() {
    return {
      searchString: '',
    };
  },
  computed: {
    allOptions() {
      const allOptions = [];

      const getOptions = (options) => {
        for (let i = 0; i < options.length; i += 1) {
          const option = options[i];
          if (option.options) {
            getOptions(option.options);
          } else {
            allOptions.push(option);
          }
        }
      };
      getOptions(this.items);

      return allOptions;
    },
    isGrouped() {
      return this.items.some((item) => item.options !== undefined);
    },
    isSearchable() {
      return this.allOptions.length > MIN_ITEMS_COUNT_FOR_SEARCHING;
    },
    filteredItems() {
      const searchString = this.searchString.toLowerCase();

      if (!searchString) {
        return this.items;
      }

      if (this.isGrouped) {
        return this.items
          .map(({ text, options }) => {
            return {
              text,
              options: options.filter((option) => option.text.toLowerCase().includes(searchString)),
            };
          })
          .filter(({ options }) => options.length);
      }

      return this.items.filter((item) => item.text.toLowerCase().includes(searchString));
    },
    toggleText() {
      return this.selected
        ? this.allOptions.find((option) => option.value === this.selected).text
        : this.defaultToggleText;
    },
  },
  methods: {
    search(searchString) {
      this.searchString = searchString;
    },
  },
};
</script>

<template>
  <gl-form-group :label="label">
    <gl-listbox
      :selected="selected"
      :toggle-text="toggleText"
      :items="filteredItems"
      :searchable="isSearchable"
      :no-results-text="$options.i18n.noResultsText"
      @search="search"
      @select="$emit($options.model.event, $event)"
    />
    <input ref="input" type="hidden" :name="name" :value="selected" />
  </gl-form-group>
</template>
