package com.microsoft.azure.productservice.services;

import org.springframework.stereotype.Service;
import com.microsoft.azure.productservice.model.Product;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

@Service
public class ProductService {
    private final List<Product> products;
    private int nextId = 11;

    public ProductService() {
        products = new ArrayList<>(defaultProducts());
    }

    private static List<Product> defaultProducts() {
        return List.of(
            new Product(1, "Captain Catnip's Fisherman's Friend", 9.99f, "Watch your feline friend embark on a fishing adventure with Captain Catnip's Fisherman's Friend toy. Packed with irresistible catnip and dangling fish lure.", "/placeholder.png"),
            new Product(2, "Salty Sailor's Squeaky Squid", 6.99f, "Let your dog set sail with the Salty Sailor's Squeaky Squid. This interactive toy provides hours of fun, featuring multiple squeakers and crinkle tentacles.", "/placeholder.png"),
            new Product(3, "Mermaid's Mice Trio", 12.99f, "Entertain your kitty with the Mermaid's Mice Trio. These adorable plush mice are dressed as mermaids and filled with catnip to captivate their curiosity.", "/placeholder.png"),
            new Product(4, "Ocean Explorer's Puzzle Ball", 11.99f, "Challenge your pet's problem-solving skills with the Ocean Explorer's Puzzle Ball. This interactive toy features hidden compartments and treats, providing mental stimulation and entertainment.", "/placeholder.png"),
            new Product(5, "Pirate Parrot Teaser Wand", 8.99f, "Engage your cat in a playful pursuit with the Pirate Parrot Teaser Wand. The colorful feathers and jingling bells mimic the mischievous charm of a pirate's parrot.", "/placeholder.png"),
            new Product(6, "Seafarer's Tug Rope", 14.99f, "Tug-of-war meets nautical adventure with the Seafarer's Tug Rope. Made from marine-grade rope, it's perfect for interactive play and promoting dental health in dogs.", "/placeholder.png"),
            new Product(7, "Seashell Snuggle Bed", 19.99f, "Give your furry friend a cozy spot to curl up with the Seashell Snuggle Bed. Shaped like a seashell, this plush bed provides comfort and relaxation for cats and small dogs.", "/placeholder.png"),
            new Product(8, "Nautical Knot Ball", 7.99f, "Unleash your dog's inner sailor with the Nautical Knot Ball. Made from sturdy ropes, it's perfect for fetching, tugging, and satisfying their chewing needs.", "/placeholder.png"),
            new Product(9, "Captain Claw's Crab Cat Toy", 3.99f, "Watch your cat go crazy for Captain Claw's Crab Cat Toy. This crinkly and catnip-filled toy will awaken their hunting instincts and provide endless entertainment.", "/placeholder.png"),
            new Product(10, "Ahoy Doggy Life Jacket", 5.99f, "Ensure your furry friend stays safe during water adventures with the Ahoy Doggy Life Jacket. Designed for dogs, this flotation device offers buoyancy and visibility in style.", "/placeholder.png")
        );
    }

    public List<Product> getAllProducts() {
        return Collections.unmodifiableList(products);
    }

    public Optional<Product> getProductById(int id) {
        return products.stream()
                    .filter(product -> product.id() == id)
                    .findFirst();
    }


    public Product addProduct(Product product) {
        var newProduct = new Product(nextId++, product.name(), product.price(), product.description(), product.image());
        products.add(newProduct);
        return newProduct;
    }

    public Optional<Product> updateProduct(Product product) {
        var existingProduct = getProductById(product.id());

        if (existingProduct.isPresent()) {
            var index = products.indexOf(existingProduct.get());
            products.set(index, product);
            return Optional.of(product);
        }

        return Optional.empty();
    }

    public boolean deleteProduct(int id) {
        var existingProduct = getProductById(id);
        if (existingProduct.isPresent()) {
            return products.remove(existingProduct.get());
        }
        return false;
    }

}