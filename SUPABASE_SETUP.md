# Supabase Setup Guide# Supabase Setup Guide



## Authentication Setup## Database Setup



This app uses **Supabase Auth** for email/password authentication. Users can sign up, log in, and manage their own availability.### 1. Create the `users` table



### 1. Enable Email AuthenticationRun this SQL in your Supabase SQL Editor:



1. Go to **Authentication** > **Providers** in your Supabase Dashboard```sql

2. Enable **Email** provider-- Create users table

3. Configure email templates (optional, but recommended):CREATE TABLE public.users (

   - Confirmation email  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

   - Password reset email  name text NOT NULL,

  photo_url text,

## Database Setup  created_at timestamptz NOT NULL DEFAULT now()

);

### 2. Create the `users` table

-- Enable Row Level Security (RLS)

Run this SQL in your Supabase SQL Editor:ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;



```sql-- Create policy to allow anyone to insert users (for onboarding)

-- Create users table linked to auth.usersCREATE POLICY "Allow insert for all users" ON public.users

CREATE TABLE public.users (  FOR INSERT

  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,  WITH CHECK (true);

  name text NOT NULL,

  email text NOT NULL UNIQUE,-- Create policy to allow users to read all profiles

  photo_url text,CREATE POLICY "Allow read for all users" ON public.users

  created_at timestamptz NOT NULL DEFAULT now()  FOR SELECT

);  USING (true);

```

-- Enable Row Level Security (RLS)

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;## Storage Setup



-- Policy: Users can read all profiles### 2. Create the `profile` storage bucket

CREATE POLICY "Allow read for all users" ON public.users

  FOR SELECT1. Go to **Storage** in your Supabase Dashboard

  USING (true);2. Click **"New Bucket"**

3. Name it: `profile`

-- Policy: Users can insert their own profile during signup4. Make it **Public** (so profile images can be accessed)

CREATE POLICY "Allow insert for authenticated users" ON public.users5. Click **"Create Bucket"**

  FOR INSERT

  WITH CHECK (auth.uid() = id);### 3. Set up Storage Policies



-- Policy: Users can update their own profileIn the Storage section, click on the `profile` bucket and add these policies:

CREATE POLICY "Allow update for own profile" ON public.users

  FOR UPDATE```sql

  USING (auth.uid() = id)-- Allow anyone to upload profile images

  WITH CHECK (auth.uid() = id);CREATE POLICY "Allow public uploads" ON storage.objects

```  FOR INSERT

  WITH CHECK (bucket_id = 'profile');

### 3. Create the `availability` table

-- Allow public read access to profile images

```sqlCREATE POLICY "Allow public reads" ON storage.objects

-- Create availability table  FOR SELECT

CREATE TABLE public.availability (  USING (bucket_id = 'profile');

  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),```

  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  start_time timestamptz NOT NULL,## Verification

  end_time timestamptz NOT NULL,

  created_at timestamptz NOT NULL DEFAULT now()After setup, test by:

);1. Running your Flutter app

2. Entering a name

-- Enable Row Level Security (RLS)3. Optionally selecting a photo

ALTER TABLE public.availability ENABLE ROW LEVEL SECURITY;4. Clicking "Continue"



-- Policy: Users can read all availability slotsCheck in Supabase:

CREATE POLICY "Allow read for all users" ON public.availability- **Database > users table**: Your user entry should appear

  FOR SELECT- **Storage > profile bucket**: Your uploaded image should appear (if you selected one)

  USING (true);

## Project Structure

-- Policy: Users can insert their own availability

CREATE POLICY "Allow insert for own availability" ON public.availability```

  FOR INSERTlib/

  WITH CHECK (auth.uid() = user_id);├── models/

│   └── user_model.dart          # User data model

-- Policy: Users can update their own availability├── cubits/

CREATE POLICY "Allow update for own availability" ON public.availability│   └── onboarding/

  FOR UPDATE│       ├── onboarding_cubit.dart   # Business logic

  USING (auth.uid() = user_id)│       └── onboarding_state.dart   # State management

  WITH CHECK (auth.uid() = user_id);└── pages/

    └── onboarding_page.dart     # UI with BLoC integration

-- Policy: Users can delete their own availability```

CREATE POLICY "Allow delete for own availability" ON public.availability

  FOR DELETE## Features Implemented

  USING (auth.uid() = user_id);

```✅ BLoC/Cubit state management  

✅ Image upload to Supabase Storage (`profile` bucket)  

## Storage Setup✅ User data saved to Supabase Database (`users` table)  

✅ Loading states with spinner  

### 4. Create the `profile` storage bucket✅ Error handling with user-friendly messages  

✅ Optional photo upload  

1. Go to **Storage** in your Supabase Dashboard
2. Click **"New Bucket"**
3. Name it: `profile`
4. Make it **Public** (so profile images can be accessed)
5. Click **"Create Bucket"**

### 5. Set up Storage Policies

In the Storage section, click on the `profile` bucket and add these policies:

```sql
-- Allow authenticated users to upload profile images
CREATE POLICY "Allow authenticated uploads" ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'profile' AND auth.role() = 'authenticated');

-- Allow public read access to profile images
CREATE POLICY "Allow public reads" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'profile');

-- Allow users to update their own profile images (optional)
CREATE POLICY "Allow authenticated updates" ON storage.objects
  FOR UPDATE
  USING (bucket_id = 'profile' AND auth.role() = 'authenticated')
  WITH CHECK (bucket_id = 'profile' AND auth.role() = 'authenticated');
```

## Verification

After setup, test by:
1. Running your Flutter app
2. Creating a new account with email/password
3. Optionally selecting a profile photo
4. Logging in with your credentials
5. Adding availability slots
6. Logging out and logging back in

Check in Supabase:
- **Authentication > Users**: Your user entry should appear
- **Database > users table**: Your user profile should appear
- **Database > availability table**: Your availability slots should appear
- **Storage > profile bucket**: Your uploaded image should appear (if you selected one)

## Features Implemented

✅ Email/Password Authentication (Sign up, Sign in, Sign out)  
✅ Password Reset functionality  
✅ BLoC/Cubit state management  
✅ User profile management with optional photo  
✅ Image upload to Supabase Storage (`profile` bucket)  
✅ User-specific availability management  
✅ Row Level Security (RLS) for data protection  
✅ Automatic auth state management and routing  
✅ Loading states with spinner  
✅ Error handling with user-friendly messages  

## Project Structure

```
lib/
├── main.dart                    # App entry point with auth routing
├── data/
│   ├── models/
│   │   ├── user_model.dart      # User data model
│   │   └── availability_model.dart  # Availability data model
│   └── services/
│       └── auth_service.dart    # Authentication service
├── logic/
│   ├── auth/
│   │   ├── auth_cubit.dart      # Auth business logic
│   │   └── auth_state.dart      # Auth state management
│   ├── availability/
│   │   ├── availability_cubit.dart   # Availability business logic
│   │   └── availability_state.dart   # Availability state management
│   └── user/
│       ├── user_cubit.dart      # User business logic
│       └── user_state.dart      # User state management
└── presentation/
    ├── auth/
    │   ├── login_screen.dart    # Login UI
    │   └── signup_screen.dart   # Signup UI
    ├── availability/
    │   └── availability_screen.dart  # Availability management UI
    └── onboarding/
        └── onboarding_screen.dart   # Legacy onboarding (not used)
```

## Security Notes

- All user data is protected with Row Level Security (RLS)
- Users can only modify their own data
- Authentication is required for most operations
- Profile images are public but uploads require authentication
- Password reset emails are sent via Supabase Auth
