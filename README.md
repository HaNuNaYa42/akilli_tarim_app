#  Akıllı Tarım — Bitki Hastalığı Teşhis Asistanı

Çiftçinin doğal dilde tarif ettiği belirtilerden ve/veya bitki fotoğrafından yola çıkarak hastalık tahmini ve ilaçlama önerisi üreten hibrit AI uygulaması.

[![HuggingFace Model](https://img.shields.io/badge/🤗%20HuggingFace-Model-yellow)](https://huggingface.co/haticenuryavas/qwen2.5-1.5b-tarim-lora-seed42)
[![HuggingFace API](https://img.shields.io/badge/🤗%20HuggingFace-API%20Space-blue)](https://huggingface.co/spaces/haticenuryavas/akilli-tarim-api)

---

##  İçindekiler

- [Proje Hakkında](#proje-hakkında)
- [Benchmark Sonuçları](#benchmark-sonuçları)
- [Kurulum](#kurulum)
- [Çalıştırma](#çalıştırma)
- [Proje Yapısı](#proje-yapısı)
- [Seed Değerleri](#seed-değerleri)
- [Veri Seti](#veri-seti)
- [API](#api)

---

##  Proje Hakkında

Bu proje, PlantVillage veri setinden türetilmiş Türkçe metin açıklamaları kullanarak **19 bitki hastalığı sınıfı** için teşhis ve tedavi reçetesi üretmektedir.

**Desteklenen bitkiler:** Mısır, Domates, Patates, Biber  
**Toplam sınıf:** 19 (hastalıklı + sağlıklı)  
**Dil:** Türkçe  
**Fine-tuning yöntemi:** LoRA (r=16, alpha=32)

---

##  Benchmark Sonuçları

### Zero-shot Baseline (ort ± std, 3 seed)

| Model | Accuracy | Macro F1 | ROUGE-1 | GPU (GB) |
|-------|----------|----------|---------|----------|
| SmolLM2-360M | 0.0544 ± 0.0000 | 0.0054 ± 0.0000 | 0.1608 ± 0.0016 | 0.26 |
| TinyLlama-1.1B | 0.0544 ± 0.0000 | 0.0054 ± 0.0000 | 0.1450 ± 0.0012 | 0.79 |
| Qwen2.5-1.5B | 0.0544 ± 0.0000 | 0.0054 ± 0.0000 | 0.1654 ± 0.0014 | 1.16 |
| Gemma4-E2B | 0.0544 ± 0.0000 | 0.0054 ± 0.0000 | 0.1513 ± 0.0009 | 6.40 |

### LoRA Fine-tuning (ort ± std, 3 seed)

| Model | Parametre | Accuracy | Macro F1 | ROUGE-1 | Eğitim (dk) | GPU (GB) |
|-------|-----------|----------|----------|---------|-------------|----------|
| SmolLM2-360M | 360M | 0.5827 ± 0.0157 | 0.5509 ± 0.0223 | 0.2994 ± 0.0058 | 16.0 ± 0.1 | 1.31 |
| TinyLlama-1.1B | 1.1B | 0.9569 ± 0.0275 | 0.9549 ± 0.0291 | 0.3217 ± 0.0022 | 11.4 ± 0.1 | 1.91 |
| Qwen2.5-1.5B | 1.5B | **0.9637 ± 0.0142** | **0.9620 ± 0.0151** | **0.4078 ± 0.0059** | 14.6 ± 0.1 | 3.85 |
| Gemma4-E2B | ~2B | 0.9547 ± 0.0104 | 0.9535 ± 0.0100 | 0.3688 ± 0.0249 | 46.6 ± 0.1 | 15.93 |

>  **En iyi model:** Qwen2.5-1.5B — Accuracy %96.4, ROUGE-1 0.408

---

##  Kurulum

### Gereksinimler

- Python 3.11+
- CUDA destekli GPU (eğitim için A100 önerilir)
- Flutter 3.32+
- Google Colab veya yerel GPU ortamı

### Python bağımlılıkları

```bash
pip install -r requirements.txt
```

**requirements.txt:**
```
torch>=2.0.0
transformers>=4.46.0
peft>=0.13.0
trl>=0.12.0
accelerate>=1.0.0
bitsandbytes>=0.46.1
datasets>=3.1.0
scikit-learn
rouge-score
pandas
numpy
matplotlib
huggingface_hub
```

### Flutter bağımlılıkları

```bash
cd flutter_app
flutter pub get
```

**pubspec.yaml bağımlılıkları:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.7
  http: ^1.2.0
```

---

##  Çalıştırma

modeller.ipynb dosyasındaki scriptleri sırası ile çalıştırınız. sonrasında tüm model ve sonuçları elde edebilrisiniz. Yalnızca model eğitim aşamaları mevcuttur. flutter ile arayüz ve model arasındaki bağlantıların detayları verilmemiştir. 

---

## 🌱 Seed Değerleri

Tekrarlanabilirlik için tüm deneylerde aşağıdaki seed değerleri kullanılmıştır:

```python
SEEDS = [42, 123, 7]

# Her scriptin başında:
import random, numpy as np, torch
random.seed(seed)
np.random.seed(seed)
torch.manual_seed(seed)
```

| Seed | Açıklama |
|------|----------|
| 42 | Birincil seed — model karşılaştırmalarında kullanılan |
| 123 | İkincil seed |
| 7 | Üçüncül seed |

Sonuçlar 3 seed üzerinden **ort ± std** formatında raporlanmıştır.

---

## 📦 Veri Seti

| Alan | Bilgi |
|------|-------|
| Kaynak | PlantVillage (Kaggle) | Görüntü Labelleri
| Kaynak | Sentetik olarak üretilen metin tabanlı veriseti | akilli_tarim_receteli_dataset.csv
| Boyut | 1.461 örnek | 2.850 metin 
| Dil | Türkçe |
| Sınıf sayısı | 19 |
| Bölme | %80 train / %10 val / %10 test |
| Format | ChatML (SmolLM2/TinyLlama/Qwen), Gemma4 Chat |
| Lisans | Özel / Eğitim amaçlı |

**Sınıf dağılımı:** Dengeli (min: 69, max: 84 örnek/sınıf)

---

## 🔌 API

**Base URL:** `https://haticenuryavas-akilli-tarim-api.hf.space`

### POST `/predict`

| Alan | Tip | Açıklama |
|------|-----|----------|
| `image` | file (opsiyonel) | Bitki fotoğrafı |
| `text` | string (opsiyonel) | Belirti açıklaması |

**Örnek istek:**
```python
import requests

with open("bitki.jpg", "rb") as f:
    r = requests.post(
        "https://haticenuryavas-akilli-tarim-api.hf.space/predict",
        files={"image": f},
        data={"text": "yapraklarda kahverengi lekeler var"}
    )
print(r.json())
```

**Örnek yanıt:**
```json
{
  "label": "Tomato___Early_blight",
  "label_turkce": "Domates Erken Yanıklığı",
  "confidence": 0.94,
  "recete": "Alt yaprakları budayarak hava akımını artırın...",
  "kaynak": "ikisi_ayni",
  "detay": {
    "goruntu": {"label": "Tomato___Early_blight", "confidence": 0.96},
    "metin":   {"label": "Tomato___Early_blight", "confidence": 0.88}
  }
}
```

### GET `/health`

```bash
curl https://haticenuryavas-akilli-tarim-api.hf.space/health
```

---

## 🤗 HuggingFace

| Model | Link |
|-------|------|
| Qwen2.5-1.5B (seed 42) | [haticenuryavas/qwen2.5-1.5b-tarim-lora-seed42](https://huggingface.co/haticenuryavas/qwen2.5-1.5b-tarim-lora-seed42) |
| API Space | [haticenuryavas/akilli-tarim-api](https://huggingface.co/spaces/haticenuryavas/akilli-tarim-api) |

---

## 📄 Lisans

Bu proje eğitim amaçlı geliştirilmiştir.
