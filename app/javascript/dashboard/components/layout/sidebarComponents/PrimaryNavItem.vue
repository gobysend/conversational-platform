<template>
  <div class="menu-item" :class="href ? 'external' : ''">
    <a :href="href" v-if="href">
      <fluent-icon :icon="icon" :size="18" />
      <span>{{ name }}</span>
    </a>

    <router-link v-slot="{ href, isActive, navigate }" :to="to" custom v-else>
      <a
        :href="href"
        :class="{ 'is-active': isActive || isChildMenuActive }"
        @click="navigate"
      >
        <fluent-icon :icon="icon" :size="18" />
        <span>{{ name }}</span>
      </a>
    </router-link>

    <ul class="sub-menu" v-if="children && children.length">
      <li class="sub-menu-item" v-for="(child, index) in children" :key="index">
        <a :href="href" v-if="child.href">
          <fluent-icon :icon="child.icon" :size="16" />
          <span>{{ child.label }}</span>
        </a>

        <router-link
          v-slot="{ href, isActive, navigate }"
          :to="child.toState"
          custom
          v-else
        >
          <a
            :href="href"
            :class="{ 'is-active': isActive || isChildMenuActive }"
            @click="navigate"
          >
            <fluent-icon :icon="child.icon" :size="16" />
            <span>{{ $t(`SIDEBAR.${child.label}`) }}</span>
          </a>
        </router-link>
      </li>
    </ul>
  </div>
</template>
<script>
export default {
  props: {
    to: {
      type: String,
      default: '',
    },
    href: {
      type: String,
      default: '',
    },
    children: {
      type: Array | undefined,
      default: () => [],
    },
    name: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      default: '',
    },
    count: {
      type: String,
      default: '',
    },
    isChildMenuActive: {
      type: Boolean,
      default: false,
    },
  },
};
</script>
<style lang="scss" scoped>
.button {
  margin: var(--space-small) 0;
}

.menu-item {
  position: relative;
  // border-radius: var(--border-radius-large);
  // border: 1px solid transparent;

  &.is-active {
    background: var(--w-50);
    color: var(--w-500);
  }

  & > a {
    display: flex;
    align-items: center;
    padding: 0;
    height: 50px;
    width: 100%;
    color: #fff;

    svg {
      margin: 0 15px 0 20px;
    }
  }

  .sub-menu {
    list-style: none;
    margin: 0;
    padding: 5px;
    background: rgb(101, 105, 223);

    &-item {
      padding: 4px;

      & > a {
        display: flex;
        align-items: center;
        color: #fff;
        padding: 7px 12px;

        svg {
          margin-right: 10px;
        }
      }
    }
  }

  &.external {
    .sub-menu {
      display: none;
      position: absolute;
      left: 100%;
      top: 0;
      width: 200px;                                   
    }

    &:hover {
      .sub-menu {
        display: block;
      }
    }
  }
}

.icon {
  font-size: var(--font-size-default);
}

.badge {
  position: absolute;
  right: var(--space-minus-smaller);
  top: var(--space-minus-smaller);
}
</style>
