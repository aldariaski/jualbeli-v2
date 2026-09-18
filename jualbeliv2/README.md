# JualBeli V2

JualBeli V2 is a Flutter application designed for managing product listings, allowing users to search, add, and view products seamlessly.

## Features

- **Product Search**: Users can search for products using a dedicated search bar.
- **Product Management**: Add new products and view existing ones.
- **User Authentication**: Users can log in and log out, with their session managed securely.

## Project Structure

```
jualbeliv2
├── lib
│   ├── app
│   │   └── router.dart          # Routing logic for the application
│   ├── features
│   │   └── products
│   │       ├── data
│   │       │   └── product_repository.dart  # Handles data operations for products
│   │       ├── models
│   │       │   └── product.dart  # Defines the structure of a product object
│   │       └── presentation
│   │           └── product_search_page.dart  # Displays the product search interface
│   └── shared
│       └── widgets
│           └── app_search_bar.dart  # Provides the search input field and action buttons
├── pubspec.yaml                    # Flutter project configuration
└── README.md                       # Project documentation
```

## Setup Instructions

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd jualbeliv2
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. Run the application:
   ```
   flutter run
   ```

## Usage Guidelines

- To search for products, use the search bar located at the top of the main screen.
- Users can add new products by navigating to the add product page.
- Ensure you are logged in to access all features of the application.

## Contributing

Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.