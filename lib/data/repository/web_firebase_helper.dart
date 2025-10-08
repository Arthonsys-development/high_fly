// Web-specific Firebase phone authentication helper
// This file contains JavaScript interop for Firebase phone auth on web

import 'dart:html' as html;
import 'dart:js' as js;

class WebFirebaseAuth {
  static Future<void> initializeRecaptcha() async {
    try {
      // Check if Firebase is available
      if (js.context['firebase'] == null) {
        throw 'Firebase not initialized. Please check web/index.html configuration.';
      }
      
      print('🔥 Web Firebase: Firebase JS SDK detected');
      print('🔥 Web Firebase: Project: high-fly-21a85');
      
      // Initialize reCAPTCHA container
      final container = html.document.getElementById('recaptcha-container');
      if (container != null) {
        container.style.display = 'none'; // Initially hidden
        if (container is html.HtmlElement) {
          (container as html.HtmlElement).innerHtml = ''; // Clear any existing content
        }
        print('🔥 Web Firebase: reCAPTCHA container ready');
      } else {
        print('🔥 Web Firebase: Warning - reCAPTCHA container not found');
      }
      
      // Add loading indicator
      _addLoadingIndicator();
      
    } catch (e) {
      print('🔥 Web Firebase: Error initializing reCAPTCHA: $e');
      rethrow;
    }
  }
  
  static void hideRecaptcha() {
    final container = html.document.getElementById('recaptcha-container');
    if (container != null) {
      container.style.display = 'none';
      print('🔥 Web Firebase: reCAPTCHA hidden');
    }
  }
  
  static void showRecaptcha() {
    final container = html.document.getElementById('recaptcha-container');
    if (container != null) {
      container.style.display = 'flex';
      print('🔥 Web Firebase: reCAPTCHA shown');
    }
  }
  
  static void _addLoadingIndicator() {
    final container = html.document.getElementById('recaptcha-container');
    if (container != null && container is html.HtmlElement) {
      (container as html.HtmlElement).innerHtml = '''
        <div style="
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 16px;
          padding: 20px;
        ">
          <div style="
            width: 24px;
            height: 24px;
            border: 3px solid #f0f0f0;
            border-top: 3px solid #007bff;
            border-radius: 50%;
            animation: spin 1s linear infinite;
          "></div>
          <div style="
            color: #666;
            font-size: 14px;
            text-align: center;
          ">Preparing phone verification...</div>
        </div>
        <style>
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        </style>
      ''';
    }
  }
  
  static void showError(String message) {
    final container = html.document.getElementById('recaptcha-container');
    if (container != null && container is html.HtmlElement) {
      (container as html.HtmlElement).innerHtml = '''
        <div style="
          background: #fee;
          border: 1px solid #fcc;
          border-radius: 8px;
          padding: 16px;
          color: #c33;
          font-size: 14px;
          max-width: 400px;
          text-align: center;
        ">
          <strong>Phone Verification Error</strong><br><br>
          $message
        </div>
      ''';
      container.style.display = 'flex';
    }
  }
}