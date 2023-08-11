package com.microsoft.azure.productservice.model;

public record Product(int id, String name, float price, String description, String image) {
}