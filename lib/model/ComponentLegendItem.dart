class ComponentLegendItem {
  // ₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉
  static final Map LABELS = {
    "SO2": "SO₂",
    "NO2": "NO₂",
    "CO": "CO",
    "O3": "O₃",
    "PM10": "PM₁₀",
    "PM2_5": "PM₂ ₅",
    "SO2": "SO₂",
  };

  String code;
  String name;
  String unit;

  ComponentLegendItem(code, name, unit) {
    print(code);
    print(LABELS.containsKey(code));
    print(LABELS[code]);

    
    this.code = LABELS.containsKey(code) ? LABELS[code] : code;
    print(this.code);
    print("## lel");
    this.name = name;
    this.unit = unit;
  }
}
