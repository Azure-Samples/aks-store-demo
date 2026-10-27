import { beforeEach, describe, it, expect } from "vitest"
import { nextTick } from "vue"
import { createPinia } from "pinia"

import { mount } from "@vue/test-utils"
import { useCartStore } from "@/stores"
import TopNav from "../TopNav.vue"

function mountNav() {
  return mount(TopNav, {
    global: {
      plugins: [createPinia()],
      stubs: { RouterLink: true },
      renderStubDefaultSlot: true,
    },
  })
}

describe("TopNav", () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it("renders properly", () => {
    const wrapper = mountNav()
    expect(wrapper.find("nav").exists()).toBe(true)
    expect(wrapper.find(".logo").exists()).toBe(true)
    expect(wrapper.find(".logo img").attributes("alt")).toBe("Contoso Pet Store Logo")
  })

  it("contains navigation links", () => {
    const wrapper = mountNav()
    expect(wrapper.find(".nav-links").exists()).toBe(true)
    expect(wrapper.findAll(".nav-links li").length).toBe(2)
    const links = wrapper.findAll(".nav-links router-link-stub")
    expect(links.at(0)?.attributes("to")).toBe("/")
    expect(links.at(1)?.attributes("to")).toBe("/cart")
  })

  it("updates the cart count when items are added", async () => {
    const wrapper = mountNav()
    expect(wrapper.find(".nav-links").text()).toContain("Cart (0)")

    useCartStore().addItem({
      product: { id: 1, name: "Test product", price: 5 },
      quantity: 2,
    })
    await nextTick()

    expect(wrapper.find(".nav-links").text()).toContain("Cart (2)")
  })

  it("toggles mobile menu when hamburger is clicked", async () => {
    const wrapper = mountNav()
    expect(wrapper.find(".nav-links").classes()).not.toContain("nav-links--open")

    await wrapper.find(".hamburger").trigger("click")
    expect(wrapper.find(".nav-links").classes()).toContain("nav-links--open")

    await wrapper.find(".hamburger").trigger("click")
    expect(wrapper.find(".nav-links").classes()).not.toContain("nav-links--open")
  })

  it("closes the mobile menu when a navigation link is clicked", async () => {
    const wrapper = mountNav()
    await wrapper.find(".hamburger").trigger("click")
    expect(wrapper.find(".nav-links").classes()).toContain("nav-links--open")

    await wrapper.find(".nav-links router-link-stub").trigger("click")

    expect(wrapper.find(".nav-links").classes()).not.toContain("nav-links--open")
  })
})
