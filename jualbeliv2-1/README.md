# JualBeli V2

JualBeli V2 is a Flutter application designed for buying and selling products online. This application allows users to search for products across various categories, view product details, and connect with sellers.

## Features

- **Product Search**: Users can search for products by name or category.
- **Product Listings**: A comprehensive list of products with details such as name, price, image, and seller information.
- **Category Filtering**: Users can filter products by predefined categories.
- **Responsive Design**: The application is designed to work on various screen sizes.

## Getting Started

To get started with the JualBeli V2 application, follow these steps:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/jualbeliv2.git
   ```

2. **Navigate to the Project Directory**:
   ```bash
   cd jualbeliv2
   ```

3. **Install Dependencies**:
   Make sure you have Flutter installed on your machine. Then run:
   ```bash
   flutter pub get
   ```

4. **Run the Application**:
   You can run the application using:
   ```bash
   flutter run
   ```

## Project Structure

The project is organized as follows:

```
lib/
├── features/
│   └── product/
│       ├── data/
│       │   └── product_model.dart
│       └── presentation/
│           ├── pages/
│           │   └── product_search_page.dart
│           └── widgets/
│               ├── product_search_bar.dart
│               └── product_list.dart
└── main.dart
```

## Contributing

Contributions are welcome! If you have suggestions for improvements or new features, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.