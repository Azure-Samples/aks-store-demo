use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Serialize, Deserialize, Clone, Debug, PartialEq)]
pub struct Product {
    pub id: i32,
    pub name: String,
    pub price: f32,
    pub description: String,
    pub image: String,
}

#[derive(Deserialize)]
pub struct ProductPath {
    pub product_id: i32,
}

#[derive(Debug, Clone, PartialEq)]
pub enum ValidationError {
    EmptyName,
    EmptyDescription,
    EmptyImage,
    NegativePrice,
}

impl fmt::Display for ValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::EmptyName => write!(f, "Product name cannot be empty"),
            Self::EmptyDescription => write!(f, "Product description cannot be empty"),
            Self::EmptyImage => write!(f, "Product image cannot be empty"),
            Self::NegativePrice => write!(f, "Product price cannot be negative"),
        }
    }
}

pub fn validate_product(product: &Product) -> Result<(), ValidationError> {
    if product.name.trim().is_empty() {
        return Err(ValidationError::EmptyName);
    }
    if product.description.trim().is_empty() {
        return Err(ValidationError::EmptyDescription);
    }
    if product.image.trim().is_empty() {
        return Err(ValidationError::EmptyImage);
    }
    if product.price < 0.0 {
        return Err(ValidationError::NegativePrice);
    }
    Ok(())
}

#[derive(Debug, Clone, PartialEq)]
pub enum StoreError {
    NotFound(i32),
    Validation(ValidationError),
}

impl fmt::Display for StoreError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::NotFound(id) => write!(f, "Product with id {id} not found"),
            Self::Validation(e) => write!(f, "{e}"),
        }
    }
}

impl From<ValidationError> for StoreError {
    fn from(e: ValidationError) -> Self {
        Self::Validation(e)
    }
}

pub struct ProductStore {
    products: Vec<Product>,
    next_id: i32,
}

impl ProductStore {
    pub fn new(products: Vec<Product>) -> Self {
        let next_id = products.iter().map(|p| p.id).max().unwrap_or(0) + 1;
        Self { products, next_id }
    }

    pub fn list(&self) -> &[Product] {
        &self.products
    }

    pub fn find(&self, id: i32) -> Result<&Product, StoreError> {
        self.products
            .iter()
            .find(|p| p.id == id)
            .ok_or(StoreError::NotFound(id))
    }

    pub fn insert(&mut self, mut product: Product) -> Result<Product, StoreError> {
        validate_product(&product)?;
        product.id = self.next_id;
        self.next_id += 1;
        self.products.push(product.clone());
        Ok(product)
    }

    pub fn update(&mut self, product: Product) -> Result<Product, StoreError> {
        validate_product(&product)?;
        let index = self
            .products
            .iter()
            .position(|p| p.id == product.id)
            .ok_or(StoreError::NotFound(product.id))?;
        self.products[index] = product.clone();
        Ok(product)
    }

    pub fn delete(&mut self, id: i32) -> Result<(), StoreError> {
        let index = self
            .products
            .iter()
            .position(|p| p.id == id)
            .ok_or(StoreError::NotFound(id))?;
        self.products.remove(index);
        Ok(())
    }

    pub fn count(&self) -> usize {
        self.products.len()
    }
}

pub fn seed_products() -> Vec<Product> {
    vec![
        Product {
            id: 1,
            name: "Contoso Catnip's Friend".into(),
            price: 9.99,
            description: "Watch your feline friend embark on a fishing adventure with Contoso Catnip's Friend toy. Packed with irresistible catnip and dangling fish lure.".into(),
            image: "/catnip.jpg".into(),
        },
        Product {
            id: 2,
            name: "Salty Sailor's Squeaky Squid".into(),
            price: 6.99,
            description: "Let your dog set sail with the Salty Sailor's Squeaky Squid. This interactive toy provides hours of fun, featuring multiple squeakers and crinkle tentacles.".into(),
            image: "/squid.jpg".into(),
        },
        Product {
            id: 3,
            name: "Mermaid's Mice Trio".into(),
            price: 12.99,
            description: "Entertain your kitty with the Mermaid's Mice Trio. These adorable plush mice are dressed as mermaids and filled with catnip to captivate their curiosity.".into(),
            image: "/mermaid.jpg".into(),
        },
        Product {
            id: 4,
            name: "Ocean Explorer's Puzzle Ball".into(),
            price: 11.99,
            description: "Challenge your pet's problem-solving skills with the Ocean Explorer's Puzzle Ball. This interactive toy features hidden compartments and treats, providing mental stimulation and entertainment.".into(),
            image: "/ocean.jpg".into(),
        },
        Product {
            id: 5,
            name: "Pirate Parrot Teaser Wand".into(),
            price: 8.99,
            description: "Engage your cat in a playful pursuit with the Pirate Parrot Teaser Wand. The colorful feathers and jingling bells mimic the mischievous charm of a pirate's parrot.".into(),
            image: "/pirate.jpg".into(),
        },
        Product {
            id: 6,
            name: "Seafarer's Tug Rope".into(),
            price: 14.99,
            description: "Tug-of-war meets nautical adventure with the Seafarer's Tug Rope. Made from marine-grade rope, it's perfect for interactive play and promoting dental health in dogs.".into(),
            image: "/tug.jpg".into(),
        },
        Product {
            id: 7,
            name: "Seashell Snuggle Bed".into(),
            price: 19.99,
            description: "Give your furry friend a cozy spot to curl up with the Seashell Snuggle Bed. Shaped like a seashell, this plush bed provides comfort and relaxation for cats and small dogs.".into(),
            image: "/bed.jpg".into(),
        },
        Product {
            id: 8,
            name: "Nautical Knot Ball".into(),
            price: 7.99,
            description: "Unleash your dog's inner sailor with the Nautical Knot Ball. Made from sturdy ropes, it's perfect for fetching, tugging, and satisfying their chewing needs.".into(),
            image: "/knot.jpg".into(),
        },
        Product {
            id: 9,
            name: "Contoso Claw's Crabby Cat Toy".into(),
            price: 3.99,
            description: "Watch your cat go crazy for Contoso Claw's Crabby Cat Toy. This crinkly and catnip-filled toy will awaken their hunting instincts and provide endless entertainment.".into(),
            image: "/crabby.jpg".into(),
        },
        Product {
            id: 10,
            name: "Ahoy Doggy Life Jacket".into(),
            price: 5.99,
            description: "Ensure your furry friend stays safe during water adventures with the Ahoy Doggy Life Jacket. Designed for dogs, this flotation device offers buoyancy and visibility in style.".into(),
            image: "/lifejacket.jpg".into(),
        },
    ]
}

#[cfg(test)]
mod tests {
    use super::*;

    fn valid_product() -> Product {
        Product {
            id: 0,
            name: "Test Product".into(),
            price: 9.99,
            description: "A test product".into(),
            image: "/test.jpg".into(),
        }
    }

    #[test]
    fn validate_valid_product() {
        assert!(validate_product(&valid_product()).is_ok());
    }

    #[test]
    fn validate_empty_name() {
        let mut p = valid_product();
        p.name = "".into();
        assert_eq!(validate_product(&p), Err(ValidationError::EmptyName));
    }

    #[test]
    fn validate_whitespace_name() {
        let mut p = valid_product();
        p.name = "   ".into();
        assert_eq!(validate_product(&p), Err(ValidationError::EmptyName));
    }

    #[test]
    fn validate_empty_description() {
        let mut p = valid_product();
        p.description = "".into();
        assert_eq!(validate_product(&p), Err(ValidationError::EmptyDescription));
    }

    #[test]
    fn validate_empty_image() {
        let mut p = valid_product();
        p.image = "".into();
        assert_eq!(validate_product(&p), Err(ValidationError::EmptyImage));
    }

    #[test]
    fn validate_negative_price() {
        let mut p = valid_product();
        p.price = -1.0;
        assert_eq!(validate_product(&p), Err(ValidationError::NegativePrice));
    }

    #[test]
    fn validate_zero_price_ok() {
        let mut p = valid_product();
        p.price = 0.0;
        assert!(validate_product(&p).is_ok());
    }

    #[test]
    fn store_insert_assigns_id() {
        let mut store = ProductStore::new(vec![]);
        let p = store.insert(valid_product()).unwrap();
        assert_eq!(p.id, 1);

        let p2 = store.insert(valid_product()).unwrap();
        assert_eq!(p2.id, 2);
    }

    #[test]
    fn store_insert_rejects_invalid() {
        let mut store = ProductStore::new(vec![]);
        let mut p = valid_product();
        p.name = "".into();
        assert!(store.insert(p).is_err());
        assert_eq!(store.count(), 0);
    }

    #[test]
    fn store_find_existing() {
        let store = ProductStore::new(seed_products());
        let p = store.find(1).unwrap();
        assert_eq!(p.name, "Contoso Catnip's Friend");
    }

    #[test]
    fn store_find_missing() {
        let store = ProductStore::new(seed_products());
        assert_eq!(store.find(999), Err(StoreError::NotFound(999)));
    }

    #[test]
    fn store_update_existing() {
        let mut store = ProductStore::new(seed_products());
        let mut p = store.find(1).unwrap().clone();
        p.name = "Updated Name".into();
        let updated = store.update(p).unwrap();
        assert_eq!(updated.name, "Updated Name");
        assert_eq!(store.find(1).unwrap().name, "Updated Name");
    }

    #[test]
    fn store_update_missing() {
        let mut store = ProductStore::new(seed_products());
        let mut p = valid_product();
        p.id = 999;
        assert_eq!(store.update(p), Err(StoreError::NotFound(999)));
    }

    #[test]
    fn store_update_rejects_invalid() {
        let mut store = ProductStore::new(seed_products());
        let mut p = store.find(1).unwrap().clone();
        p.price = -5.0;
        assert!(store.update(p).is_err());
    }

    #[test]
    fn store_delete_existing() {
        let mut store = ProductStore::new(seed_products());
        let initial_count = store.count();
        store.delete(1).unwrap();
        assert_eq!(store.count(), initial_count - 1);
        assert!(store.find(1).is_err());
    }

    #[test]
    fn store_delete_missing() {
        let mut store = ProductStore::new(seed_products());
        assert_eq!(store.delete(999), Err(StoreError::NotFound(999)));
    }

    #[test]
    fn store_list_returns_all() {
        let store = ProductStore::new(seed_products());
        assert_eq!(store.list().len(), 10);
    }

    #[test]
    fn store_ids_never_reused_after_delete() {
        let mut store = ProductStore::new(vec![]);
        let p1 = store.insert(valid_product()).unwrap();
        let p2 = store.insert(valid_product()).unwrap();
        store.delete(p1.id).unwrap();
        let p3 = store.insert(valid_product()).unwrap();
        assert_eq!(p3.id, 3);
        assert_ne!(p3.id, p1.id);
        assert_ne!(p3.id, p2.id);
    }
}
