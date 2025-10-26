# Supabase Setup Guide

## Database Setup

### 1. Create the `users` table

Run this SQL in your Supabase SQL Editor:

```sql
-- Create users table
CREATE TABLE public.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  photo_url text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Create policy to allow anyone to insert users (for onboarding)
CREATE POLICY "Allow insert for all users" ON public.users
  FOR INSERT
  WITH CHECK (true);

-- Create policy to allow users to read all profiles
CREATE POLICY "Allow read for all users" ON public.users
  FOR SELECT
  USING (true);
```

## Storage Setup

### 2. Create the `profile` storage bucket

1. Go to **Storage** in your Supabase Dashboard
2. Click **"New Bucket"**
3. Name it: `profile`
4. Make it **Public** (so profile images can be accessed)
5. Click **"Create Bucket"**

### 3. Set up Storage Policies

In the Storage section, click on the `profile` bucket and add these policies:

```sql
-- Allow anyone to upload profile images
CREATE POLICY "Allow public uploads" ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'profile');

-- Allow public read access to profile imagesR
CREATE POLICY "Allow public reads" ON storage.objects
  FOR SELECT
  USING (bucket_id = 'profile');
```

## Verification

After setup, test by:
1. Running your Flutter app
2. Entering a name
3. Optionally selecting a photo
4. Clicking "Continue"

Check in Supabase:
- **Database > users table**: Your user entry should appear
- **Storage > profile bucket**: Your uploaded image should appear (if you selected one)

## Project Structure

```
lib/
├── models/
│   └── user_model.dart          # User data model
├── cubits/
│   └── onboarding/
│       ├── onboarding_cubit.dart   # Business logic
│       └── onboarding_state.dart   # State management
└── pages/
    └── onboarding_page.dart     # UI with BLoC integration
```

## Features Implemented

✅ BLoC/Cubit state management  
✅ Image upload to Supabase Storage (`profile` bucket)  
✅ User data saved to Supabase Database (`users` table)  
✅ Loading states with spinner  
✅ Error handling with user-friendly messages  
✅ Optional photo upload  
