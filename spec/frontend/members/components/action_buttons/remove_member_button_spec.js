import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { modalData } from 'jest/members/mock_data';
import RemoveMemberButton from '~/members/components/action_buttons/remove_member_button.vue';
import { MEMBER_TYPES } from '~/members/constants';

Vue.use(Vuex);

describe('RemoveMemberButton', () => {
  let wrapper;

  const actions = {
    showRemoveMemberModal: jest.fn(),
  };

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.user]: {
          namespaced: true,
          state: {
            memberPath: '/groups/foo-bar/-/group_members/:id',
            ...state,
          },
          actions,
        },
      },
    });
  };

  const createComponent = (propsData = {}, state) => {
    wrapper = shallowMount(RemoveMemberButton, {
      store: createStore(state),
      provide: {
        namespace: MEMBER_TYPES.user,
      },
      propsData: {
        memberId: 1,
        memberType: 'GroupMember',
        message: 'Are you sure you want to remove John Smith?',
        title: 'Remove member',
        isAccessRequest: true,
        isInvite: true,
        userDeletionObstacles: { name: 'user', obstacles: [] },
        ...propsData,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('sets attributes on button', () => {
    expect(wrapper.attributes()).toMatchObject({
      'aria-label': 'Remove member',
      title: 'Remove member',
    });
  });

  it('displays `title` prop as a tooltip', () => {
    expect(getBinding(wrapper.element, 'gl-tooltip')).not.toBeUndefined();
  });

  it('calls Vuex action to show `remove member` modal when clicked', () => {
    findButton().vm.$emit('click');

    expect(actions.showRemoveMemberModal).toHaveBeenCalledWith(expect.any(Object), modalData);
  });
});
