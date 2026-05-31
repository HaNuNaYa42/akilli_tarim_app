---
title: Akilli Tarim API
emoji: 🌱
colorFrom: green
colorTo: teal
sdk: docker
pinned: false
---

# Akıllı Tarım — Bitki Hastalığı Teşhis API

Çiftçinin doğal dilde tarif ettiği belirtilerden ve/veya bitki fotoğrafından
hastalık tahmini ve ilaçlama önerisi üreten hibrit AI API.

## Endpoint

**POST** `/predict`

| Alan | Tip | Açıklama |
|---|---|---|
| `image` | file (opsiyonel) | Bitki fotoğrafı |
| `text` | string (opsiyonel) | Belirti açıklaması |

## Yanıt

```json
{
  "label": "Tomato___Early_blight",
  "label_turkce": "Domates Erken Yanıklığı",
  "confidence": 0.94,
  "recete": "Alt yaprakları budayarak...",
  "kaynak": "ikisi_ayni",
  "detay": {
    "goruntu": {"label": "...", "confidence": 0.96},
    "metin":   {"label": "...", "confidence": 0.88}
  }
}
```

## Modeller

- **Görüntü**: EfficientNet-B0 (PlantVillage fine-tuned)
- **Metin**: Qwen2.5-1.5B + LoRA (haticenuryavas/qwen2.5-1.5b-tarim-lora-seed42)
