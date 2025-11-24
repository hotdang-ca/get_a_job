# Get A Job - Flutter Job Application Tracker

A minimalist Flutter web application for tracking job applications with AI-powered cover letter generation.

## Features

- 📋 Kanban board for job tracking
- 🎨 Minimalist design with dark/light mode
- 📄 Resume upload to Supabase Storage
- 🤖 AI-powered cover letter generation (OpenAI)
- 🖱️ Drag-and-drop job cards between status columns
- 📋 Copy cover letters to clipboard

## Setup

### Prerequisites

- Flutter SDK (3.24.5 or later)
- Supabase account
- OpenAI API key

### Installation

1. Clone the repository:
```bash
git clone https://github.com/YOUR_USERNAME/get-a-job.git
cd get-a-job/get_a_job
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Supabase:
   - Copy `lib/core/constants.dart.template` to `lib/core/constants.dart`
   - Update with your Supabase URL and anon key
   - Run the SQL schema: `supabase_schema.sql` in your Supabase SQL editor
   - Create a storage bucket named `resumes` (make it public or configure RLS)

4. Deploy Supabase Edge Function:
```bash
cd supabase
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set OPENAI_API_KEY=your-openai-key
supabase functions deploy generate-cover-letter
```

5. Run the app:
```bash
flutter run -d chrome
```

## Deployment

### Build for Production

```bash
flutter build web --release
```

### Deploy to Firebase Hosting

```bash
firebase deploy --only hosting
```

### Deploy to Vercel

```bash
vercel --prod
```

## Security

- ✅ Supabase credentials are safe to expose (protected by RLS)
- ✅ OpenAI API key is stored securely in Supabase Edge Functions
- ✅ `lib/core/constants.dart` is gitignored to prevent accidental commits

## Tech Stack

- **Frontend**: Flutter Web
- **Backend**: Supabase (PostgreSQL + Storage)
- **AI**: OpenAI API (via Supabase Edge Functions)
- **State Management**: BLoC Pattern
- **Theme**: Custom minimalist design with Inter font

## License

MIT
