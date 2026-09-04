import 'package:go_router/go_router.dart';
import '../features/admin_panel/presentation/screens/admin_dashboard_screen.dart';
import '../features/auth/presentation/screens/language_selection_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/clinical_intake/presentation/screens/clinical_intake_screen.dart';
import '../features/doctor_dashboard/presentation/screens/doctor_dashboard_screen.dart';
import '../features/document_scanning/presentation/screens/document_scanner_screen.dart';
import '../features/patient_dashboard/presentation/screens/patient_dashboard_screen.dart';
import '../features/summary/presentation/screens/patient_details_consultation_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Page 1: Language Selection
    GoRoute(
      path: '/',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),

    // Page 2: Auth Login & Registration
    GoRoute(
      path: '/auth',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Page 3: Patient Dashboard
    GoRoute(
      path: '/patient-dashboard',
      builder: (context, state) => const PatientDashboardScreen(),
    ),

    // Page 4: Clinical Intake (Allopathy & AYUSH)
    GoRoute(
      path: '/clinical-intake',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'allopathy';
        return ClinicalIntakeScreen(mode: mode);
      },
    ),

    // Page 5: Doctor Dashboard
    GoRoute(
      path: '/doctor-dashboard',
      builder: (context, state) => const DoctorDashboardScreen(),
    ),

    // Page 6: Consultation Details, 3-Tier Summary & Voice Rx
    GoRoute(
      path: '/consultation/:sessionId',
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId'] ?? 'sess_101';
        return PatientDetailsConsultationScreen(sessionId: sessionId);
      },
    ),

    // Document Scanner & OCR
    GoRoute(
      path: '/document-scanner',
      builder: (context, state) => const DocumentScannerScreen(),
    ),

    // Admin Dashboard & Analytics
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
