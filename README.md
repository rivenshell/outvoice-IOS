# OutVoice - Invoice Management App

OutVoice is a simple yet powerful invoice management application built with SwiftUI and Supabase.

## Features

- User authentication with Supabase Auth
- Create, read, update, and delete invoices
- Filter and search invoices
- Generate PDF invoices

## Setup Instructions

### 1. Supabase Setup

1. Create a Supabase account at [supabase.com](https://supabase.com) if you don't have one already.
2. Create a new project in Supabase.
3. After creating your project, navigate to the SQL Editor in the Supabase dashboard.
4. Create the database schema by running the SQL script in `supabase-schema.sql` file in the SQL Editor.
5. Enable email authentication in the Auth settings of your Supabase project.

### 2. Configure the App (Secure Method)

1. Get your Supabase project URL and anon key from the API settings in your Supabase dashboard.
2. Create a copy of `SupabaseConfig.template.plist` and name it `SupabaseConfig.plist`
3. Edit `SupabaseConfig.plist` with your Supabase URL and anon key.
4. Add `SupabaseConfig.plist` to your Xcode project (make sure it's not included in version control).
5. Add `SupabaseConfig.plist` to your `.gitignore` file if you're using Git.

```
# .gitignore
SupabaseConfig.plist
```

### Alternative Configuration (for development only)

If you prefer, you can add the Supabase URL and anon key to your Info.plist file instead:

1. Open your Info.plist file.
2. Add two new keys: `SUPABASE_URL` and `SUPABASE_KEY`.
3. Set their values to your Supabase project URL and anon key.

⚠️ **Note**: This method is less secure as the Info.plist file is included in your app bundle and version control. Only use this for development, not for production apps.

## Development

This app uses the Supabase Swift SDK for authentication and database operations. The main components are:

- `AuthService`: Handles user authentication and session management
- `InvoiceService`: Manages CRUD operations for invoices
- `User`: Model for user data
- `Invoice`: Model for invoice data
- `InvoiceView`: Main view for displaying and managing invoices

## Future Enhancements

- Real-time invoice updates
- Invoice templates
- Client management
- Payment integration
- Export to different formats

## Security Considerations

- The app uses a secure method for storing Supabase credentials
- Make sure not to commit your `SupabaseConfig.plist` file to version control
- Consider implementing certificate pinning for additional security in production

## License

This project is licensed under the MIT License - see the LICENSE file for details.
