# FreshCycle

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-blue?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart_SDK-3.9.2+-blue?logo=dart" alt="Dart SDK">
  <img src="https://img.shields.io/badge/State-Management-Provider-green" alt="Provider">
  <img src="https://img.shields.io/badge/Backend-Supabase-orange" alt="Supabase">
</p>

FreshCycle is a Flutter mobile application that helps reduce food waste by enabling users to track their pantry items, generate recipes from available ingredients, and buy, sell, or request surplus food from their local community.

## Features

### Pantry Management
- Add and track food items with expiry dates
- Categories: Produce, Dairy, Bakery, Meat & Fish, Meals & Leftovers, Snacks, Beverages
- Visual urgency indicators (safe, soon, critical)
- Automatic expiry notifications
- Barcode scanning support
- OCR scanning to extract expiry dates from photos (Google ML Kit)
- Track item costs

### AI Recipe Generation
- Generate recipe suggestions from pantry items using Google Gemini AI
- Considers available ingredients and suggests missing basics via Marketplace requests
- Recipes include prep time, cook time, servings, ingredients, and step-by-step instructions

### Marketplace
- **Selling**: Post surplus food items for sale at discounted prices, with photo uploads
- **Requesting**: Request food items that users need
- Location-based filtering (barangay-level)
- Seller profiles with ratings and verification
- Save favorite listings
- Direct messaging between buyers and sellers

### Messaging System
- Real-time conversations between users
- Context-aware messaging (linked to specific listings)
- Unread message notifications

### Notifications
- Expiry warnings for pantry items
- New messages
- Listing saves by other users
- Offer updates (received, accepted, rejected)

### User Profile
- Authentication (email/password via Supabase Auth)
- Edit profile information
- Sprouts rewards system (earn points from listings and completed transactions, with confetti celebration)
- Location settings (barangay-level via geocoding)
- My listings management

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Framework** | Flutter |
| **Language** | Dart 3.9.2+ |
| **State Management** | Provider |
| **Backend** | Supabase (PostgreSQL + Auth) |
| **AI** | Google Gemini 2.5 Flash |
| **Maps** | Flutter Map + OpenStreetMap |
| **Notifications** | flutter_local_notifications |
| **OCR** | Google ML Kit (Text Recognition) |
| **Storage** | SharedPreferences |

## Project Structure

```
lib/
├── main.dart                 # App entry point & navigation shell
├── data/
│   ├── db.dart               # Supabase database operations
│   ├── sample_data.dart      # Mock data for development
│   └── sample_recipes.dart   # Sample recipes
├── models/
│   ├── listing.dart          # Marketplace listing model
│   ├── messages.dart          # Chat message model
│   ├── notification.dart     # Notification model
│   ├── pantry_item.dart      # Pantry item model
│   ├── recipe.dart           # Recipe model
│   └── user.dart             # User profile model
├── providers/
│   ├── auth_provider.dart    # Authentication state
│   ├── listing_provider.dart # Marketplace listings state
│   ├── messages_provider.dart # Chat/messages state
│   ├── navigation_provider.dart # Bottom nav state
│   └── notifications_provider.dart # Notifications state
├── screens/
│   ├── edit_profile_screen.dart
│   ├── listing_detail_screen.dart
│   ├── marketplace_screen.dart
│   ├── messages_screen.dart
│   ├── my_listings_screen.dart
│   ├── notifications_screen.dart
│   ├── pantry_screen.dart
│   ├── post_listing_screen.dart
│   ├── post_request_screen.dart
│   ├── profile_screen.dart
│   ├── recipe_detail_screen.dart
│   ├── recipes_screen.dart
│   ├── request_detail_screen.dart
│   ├── rewards_screen.dart
│   ├── saved_items_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── ai_recipe_service.dart       # Gemini AI integration
│   ├── local_notification_service.dart
│   └── pantry_notification_service.dart
├── theme/
│   └── app_theme.dart       # Material 3 theme configuration
└── widgets/                 # Reusable UI components
```

## Prerequisites

- Flutter SDK (latest stable)
- Dart SDK 3.9.2+
- Supabase project (for backend)
- Google Gemini API key (for AI recipes)

## Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd FreshCycle
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   
   Copy `.env.example` to `.env` and fill in your credentials:
   ```bash
   cp .env.example .env
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Database Schema (Supabase)

### Tables
- `profiles` - User profiles with points system
- `listings` - Marketplace items (selling/requesting)
- `conversations` - Chat threads between users
- `messages` - Individual messages
- `notifications` - User notifications
- `location_settings` - User location preferences
- `pantry_items` - User pantry inventory

## Color Scheme

| Purpose | Color | Hex |
|---------|-------|-----|
| Primary | Green | `#1D9E75` |
| Primary Light | Light Green | `#E1F5EE` |
| Critical Urgency | Red | `#E24B4A` |
| Soon Urgency | Orange | `#BA7517` |
| Safe Urgency | Green | `#639922` |
| Request Badge | Purple | `#534AB7` |

## App Screens

1. **Pantry** - Track food items and expiry
2. **Recipes** - AI-generated recipe suggestions
3. **Market** - Buy/sell/request food items
4. **Notifications** - Alerts and updates
5. **Profile** - User settings and listings

## License

This project is for educational/prototype purposes.
