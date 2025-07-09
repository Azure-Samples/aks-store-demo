import { describe, it, expect } from 'vitest'

import { mount } from '@vue/test-utils'
import TopNav from '../TopNav.vue'

describe('TopNav', () => {
  it('renders properly', () => {
    const wrapper = mount(TopNav)
    expect(wrapper.find('nav').exists()).toBe(true)
    expect(wrapper.find('.logo').exists()).toBe(true)
    expect(wrapper.find('.logo').text()).toContain('Admin Portal')
  })

  it('contains navigation links', () => {
    const wrapper = mount(TopNav)
    expect(wrapper.find('.nav-links').exists()).toBe(true)
    expect(wrapper.findAll('.nav-links li').length).toBe(2)
    expect(wrapper.findAll('router-link-stub').at(0)?.attributes('to')).toBe('/orders')
    expect(wrapper.findAll('router-link-stub').at(1)?.attributes('to')).toBe('/products')
  })

  it('toggles mobile menu when hamburger is clicked', async () => {
    const wrapper = mount(TopNav)
    expect(wrapper.find('.nav-links').classes()).not.toContain('nav-links--open')

    await wrapper.find('.hamburger').trigger('click')
    expect(wrapper.find('.nav-links').classes()).toContain('nav-links--open')

    await wrapper.find('.hamburger').trigger('click')
    expect(wrapper.find('.nav-links').classes()).not.toContain('nav-links--open')
  })
})
