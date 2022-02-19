<template>
  <div class="menu-item" :class="href ? 'external' : ''">
    <a :href="href" v-if="href">
      <fluent-icon :icon="icon" :size="18" :viewBox="iconViewBox" />
      <span>{{ $t(`SIDEBAR.${name}`) }}</span>
    </a>

    <router-link v-slot="{ href, navigate }" :to="to" custom v-else>
      <a :href="href" class="is-active" @click="navigate">
        <fluent-icon :icon="icon" :size="18" />
        <span>{{ $t(`SIDEBAR.${name}`) }}</span>
      </a>
    </router-link>

    <ul class="sub-menu" v-if="children && children.length">
      <li class="sub-menu-item" v-for="(child, index) in children" :key="index">
        <a :href="href" v-if="child.href">
          <fluent-icon :icon="child.icon" :size="16" v-if="child.icon" />
          <span>{{ $t(`SIDEBAR.${child.label}`) }}</span>
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
    iconViewBox: {
      type: String,
      default: '0 0 24 24',
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
    height: 45px;
    width: 100%;

    color: #fff;
    opacity: 0.8;
    transition: color 0.3s ease 0s;

    &.is-active {
      background: rgba(0, 0, 0, 0.13);
      opacity: 1;
    }

    &:hover {
      background: rgba(0, 0, 0, 0.06);
      opacity: 1;
    }

    svg {
      margin: 0 15px 0 20px;
    }
    span {
      line-height: 1.5;
    }
  }

  .sub-menu {
    list-style: none;
    position: relative;
    margin: 0;
    padding: 5px;
    background: #0851bf;

    &-item {
      padding: 4px;

      & > a {
        display: flex;
        align-items: center;
        padding: 7px 12px;
        border-radius: 4px;

        opacity: 0.8;
        color: #fff;
        transition: color 0.3s ease 0s;

        &:hover {
          background: rgba(0, 0, 0, 0.06);
          opacity: 1;
        }

        &.is-active {
          background: rgba(0, 0, 0, 0.07);
          opacity: 1;
          font-weight: 500;
        }

        svg {
          margin-right: 10px;
        }
        span {
          line-height: 1.5;
        }
      }
    }

    &:not(.external):after {
      content: ' ';
      position: absolute;
      pointer-events: none;
      z-index: 10000;
      left: 50%;
      bottom: 100%;
      transform: translateX(-50%);
      width: 0px;
      height: 0px;
      border-left: 12px solid transparent;
      border-right: 12px solid transparent;
      border-bottom: 10px solid #0851bf;
    }
  }

  &.external {
    .sub-menu {
      visibility: hidden;
      position: absolute;
      left: 100%;
      top: 0;
      z-index: 9999;
      border-radius: 0 5px 5px 0;
      box-shadow: rgb(0 0 0 / 20%) 0px 3px 5px;
      white-space: nowrap;

      &::after {
        content: ' ';
        position: absolute;
        pointer-events: none;
        z-index: 10000;
        top: 15px;
        width: 0px;
        left: -11px;
        height: 0px;
        border-top: 12px solid transparent;
        border-bottom: 12px solid transparent;
        border-right: 10px solid #0851bf;
      }
    }

    &:hover {
      .sub-menu {
        visibility: visible;
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
