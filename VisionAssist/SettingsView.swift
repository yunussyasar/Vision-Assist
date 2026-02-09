import SwiftUI

/// Settings view for VisionAssist customization
struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Audio Settings
                Section {
                    Toggle("Sesli Geri Bildirim", isOn: $settings.audioEnabled)
                        .accessibilityHint("Sesli duyuruları açar veya kapatır")
                    
                    if settings.audioEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Konuşma Hızı")
                                Spacer()
                                Text(String(format: "%.2f", settings.speechRate))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $settings.speechRate, in: 0.3...0.7, step: 0.02)
                                .accessibilityLabel("Konuşma hızı")
                                .accessibilityValue(String(format: "%.2f", settings.speechRate))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Ses Tonu")
                                Spacer()
                                Text(String(format: "%.1f", settings.speechPitch))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $settings.speechPitch, in: 0.8...1.2, step: 0.1)
                                .accessibilityLabel("Ses tonu")
                                .accessibilityValue(String(format: "%.1f", settings.speechPitch))
                        }
                    }
                } header: {
                    Label("Ses Ayarları", systemImage: "speaker.wave.2.fill")
                }
                
                // MARK: - Haptic Settings
                Section {
                    Toggle("Titreşim Geri Bildirimi", isOn: $settings.hapticEnabled)
                        .accessibilityHint("Titreşim bildirimlerini açar veya kapatır")
                    
                    if settings.hapticEnabled {
                        Picker("Titreşim Yoğunluğu", selection: $settings.hapticIntensity) {
                            Text("Hafif").tag(0)
                            Text("Orta").tag(1)
                            Text("Güçlü").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .accessibilityLabel("Titreşim yoğunluğu seçimi")
                    }
                } header: {
                    Label("Titreşim Ayarları", systemImage: "iphone.radiowaves.left.and.right")
                }
                
                // MARK: - Detection Settings
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Güven Eşiği")
                            Spacer()
                            Text("\(Int(settings.confidenceThreshold * 100))%")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.confidenceThreshold, in: 0.3...0.9, step: 0.05)
                            .accessibilityLabel("Güven eşiği")
                            .accessibilityValue("\(Int(settings.confidenceThreshold * 100)) yüzde")
                        Text("Düşük değer: daha fazla nesne tespit edilir ama hatalı olabilir")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duyuru Aralığı")
                            Spacer()
                            Text("\(String(format: "%.1f", settings.debounceInterval)) sn")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.debounceInterval, in: 1.0...5.0, step: 0.5)
                            .accessibilityLabel("Duyuru aralığı")
                            .accessibilityValue("\(String(format: "%.1f", settings.debounceInterval)) saniye")
                        Text("Aynı nesne için duyurular arası minimum süre")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("Algılama Ayarları", systemImage: "eye.fill")
                }
                
                // MARK: - Language Settings
                Section {
                    Picker("Sesli Geri Bildirim Dili", selection: $settings.feedbackLanguage) {
                        Text("Türkçe").tag("tr")
                        Text("English").tag("en")
                    }
                    .accessibilityLabel("Sesli geri bildirim dili")
                } header: {
                    Label("Dil Ayarları", systemImage: "globe")
                }
                
                // MARK: - Visual Settings
                Section {
                    Toggle("Nesne Kartlarını Göster", isOn: $settings.showObjectCards)
                        .accessibilityHint("Ekranda tespit edilen nesnelerin kartlarını gösterir veya gizler")
                    
                    Picker("Görünüm", selection: $settings.darkMode) {
                        Text("Sistem").tag(0)
                        Text("Açık").tag(1)
                        Text("Koyu").tag(2)
                    }
                    .accessibilityLabel("Tema seçimi")
                } header: {
                    Label("Görsel Ayarlar", systemImage: "paintbrush.fill")
                }
                
                // MARK: - Reset Section
                Section {
                    Button(role: .destructive) {
                        settings.resetToDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Varsayılana Sıfırla")
                            Spacer()
                        }
                    }
                    .accessibilityHint("Tüm ayarları varsayılan değerlere döndürür")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                    .accessibilityLabel("Ayarları kapat")
                }
            }
        }
        .preferredColorScheme(settings.colorScheme)
    }
}

#Preview {
    SettingsView()
}
