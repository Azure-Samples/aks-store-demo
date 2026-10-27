import { describe, it, expect } from 'vitest'

import { mount } from '@vue/test-utils'
import TopNav from '../TopNav.vue'

function mountNav() {
  return mount(TopNav, {
    global: {
      stubs: { RouterLink: true },
    },
  })
}

describe('TopNav', () => {
  it('renders properly', () => {
    const wrapper = mountNav()
    expect(wrapper.find('nav').exists()).toBe(true)
    expect(wrapper.find('.logo').exists()).toBe(true)
    expect(wrapper.find('.logo').text()).toContain('Admin Portal')
  })

  it('contains navigation links', () => {
    const wrapper = mountNav()
    expect(wrapper.find('.nav-links').exists()).toBe(true)
    expect(wrapper.findAll('.nav-links li').length).toBe(2)
    const links = wrapper.findAll('.nav-links router-link-stub')
    expect(links.at(0)?.attributes('to')).toBe('/orders')
    expect(links.at(1)?.attributes('to')).toBe('/products')
  })

  it('toggles mobile menu when hamburger is clicked', async () => {
    const wrapper = mountNav()
    expect(wrapper.find('.nav-links').classes()).not.toContain('nav-links--open')

    await wrapper.find('.hamburger').trigger('click')
    expect(wrapper.find('.nav-links').classes()).toContain('nav-links--open')

    await wrapper.find('.hamburger').trigger('click')
    expect(wrapper.find('.nav-links').classes()).not.toContain('nav-links--open')
  })
})
