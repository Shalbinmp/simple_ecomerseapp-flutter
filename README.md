# Infinity Scrolling E-Commerce App

A simple e-commerce app built with Flutter, featuring infinite scrolling for products, cart functionality, and Razorpay integration for payments. Users can browse products, add items to their cart, and complete orders.

## Features

- **Product Listing**: Fetches products from a free public API and displays them in an Instagram Reel-style infinite scrolling view.
- **Add to Cart**: Allows users to add products to their cart, adjust quantities, and remove items.
- **Cart View**: Users can review and modify their cart items before proceeding to checkout.
- **Razorpay Payment Integration**: Securely processes payments using Razorpay.
- **View Confirmed Orders**: Displays a list of successfully confirmed orders after payment.

## Tech Stack

- **Flutter**: For building the app’s UI and managing the application state.
- **Dio**: HTTP client used to fetch product data from a public API.
- **Hive**: Lightweight key-value database used for local cart storage.
- **Razorpay SDK**: Integrated for handling online payments.

## Screens and Functionality

1. **Home Screen**
   - Displays products fetched from the public API using infinite scrolling.
   - Users can scroll through products in a reel format, similar to Instagram.
   
2. **Product Details**
   - Allows users to view detailed information about each product.
   
3. **Cart Screen**
   - Lists all products added to the cart.
   - Users can adjust quantities, remove items, and proceed to checkout.
   
4. **Checkout Screen**
   - Integrated with Razorpay for handling payments.
   - On successful payment, the cart is cleared, and the order is confirmed.
   
5. **Confirmed Orders Screen**
   - Displays a list of all successful orders with product details.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/infinity_scrolling_project.git
   cd infinity_scrolling_project
