package com.microsoft.azure.productservice;
import java.util.Arrays;
import java.util.Collections;
import java.util.Optional;

import static org.mockito.Mockito.*;
import static org.springframework.http.HttpStatus.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.microsoft.azure.productservice.model.Product;
import com.microsoft.azure.productservice.services.ProductService;

@SpringBootTest
@AutoConfigureMockMvc
class ProductServiceApplicationTests {
    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProductService productService;

    private Product sampleProduct;
    private ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    public void setup() {
        sampleProduct = new Product(1, "Sample Product", 100f, "Sample description", "sample.png");
    }

    @Test
    public void testHealthCheck() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("UP"));
    }

	@Test
    public void testCorsConfiguration() throws Exception {
        mockMvc.perform(get("/").header("Origin", "http://example.com"))
                .andExpect(status().isOk())
                .andExpect(header().string("Access-Control-Allow-Origin", "*"));
    }

	@Test
    public void testXVersionHeader() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(header().string("X-Version", "0.2"));
    }

    @Test
    public void testGetProduct() throws Exception {
        when(productService.getProductById(1)).thenReturn(Optional.of(sampleProduct));

        mockMvc.perform(get("/{product_id}", 1))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1));
    }

    @Test
    public void testGetProducts() throws Exception {
        when(productService.getAllProducts()).thenReturn(Arrays.asList(sampleProduct));

        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(1));
    }

    @Test
    public void testAddProduct() throws Exception {
        when(productService.addProduct(any(Product.class))).thenReturn(sampleProduct);

        mockMvc.perform(post("/")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(sampleProduct)))
                .andExpect(status().is(CREATED.value()))
                .andExpect(jsonPath("$.id").value(1));
    }

    @Test
    public void testUpdateProduct() throws Exception {
        when(productService.updateProduct(any(Product.class))).thenReturn(Optional.of(sampleProduct));

        mockMvc.perform(put("/")
                .contentType(MediaType.APPLICATION_JSON)
                .content(new ObjectMapper().writeValueAsString(sampleProduct)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1));
    }

    @Test
    public void testDeleteProduct() throws Exception {
        when(productService.deleteProduct(1)).thenReturn(true);

        mockMvc.perform(delete("/{product_id}", 1))
                .andExpect(status().is(NO_CONTENT.value())); 
    }

    @Test
    public void testDeleteProductNotFound() throws Exception {
        when(productService.deleteProduct(1)).thenReturn(false);

        mockMvc.perform(delete("/{product_id}", 1))
                .andExpect(status().isNotFound());
    }
}
