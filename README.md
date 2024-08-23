# Finance Tracker App

This is a **Finance Tracker** application built with Flutter, designed to help users manage their expenses, income, and investments efficiently. The app supports multiple languages and provides features such as adding transactions, calculating net worth, and viewing an overview of financial activities.

## Features

- **Expense Management**: Add, edit, and delete expense entries. Categorize expenses for better tracking.
- **Income Management**: Track all income sources, categorize them, and manage them effectively.
- **Investment Tracking**: Add, edit, and manage investments. The app calculates the current value of investments based on real-time data.
- **Net Worth Calculation**: Automatically calculate your net worth based on your expenses, income, and investments.
- **Localization**: The app supports multiple languages including English, Portuguese, Spanish, and French.
- **Dark Mode Support**: The app adapts to the system's theme and provides a user-friendly interface in both light and dark modes.
- **Real-Time Data**: Fetch real-time stock prices and cryptocurrency values to keep your investment data accurate.

## Getting Started

### Prerequisites

- **Flutter SDK**: Make sure you have Flutter installed on your system. You can download it from [Flutter's official website](https://flutter.dev/docs/get-started/install).
- **Dart SDK**: Dart is required as Flutter uses Dart as its programming language.
- **API Keys**: The app uses the [Finnhub API](https://finnhub.io/) for fetching real-time financial data. Obtain an API key from Finnhub and replace the placeholder key in the `FinnhubService` class. The app uses the [Coingecko API](https://www.coingecko.com) for fetching real-time cryptocurrenct data. Obtain an API key from Coingecko and replace the placeholder key in the `CryptoService` class.

### Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/your-username/finance-tracker.git
   cd finance-tracker
