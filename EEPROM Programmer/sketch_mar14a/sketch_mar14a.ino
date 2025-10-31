// Définition des broches
#define DATA_PIN 2        // Broche pour l'envoi des données série vers le 74HC595
#define SHIFT_CLK 3       // Broche pour le Shift Clock (SHCP) du 74HC595
#define LATCH_CLK 4       // Broche pour le Latch Clock (STCP) du 74HC595
#define OU_PIN 15         // Broche Write Enable (WE) de l'EEPROM
#define WE_PIN 16         // Broche Write Enable (WE) de l'EEPROM
#define DATA_BUS_START 5  // Première broche du bus de données (D2 à D9)

void setup() {
  pinMode(DATA_PIN, OUTPUT);
  pinMode(SHIFT_CLK, OUTPUT);
  pinMode(LATCH_CLK, OUTPUT);
  pinMode(WE_PIN, OUTPUT);

  for (int i = 0; i < 8; i++) {
    pinMode(DATA_BUS_START + i, OUTPUT);
  }

  digitalWrite(WE_PIN, HIGH);  // Désactiver l'écriture par défaut
  Serial.begin(115200);


}

// Fonction pour envoyer une adresse 11 bits au 74HC595 avec shiftOut()
void setAddress(uint16_t address) {
  digitalWrite(LATCH_CLK, LOW);

  // Envoyer d'abord les 8 bits de poids fort
  shiftOut(DATA_PIN, SHIFT_CLK, MSBFIRST, (address >> 8) & 0xFF);

  // Ensuite les 3 bits de poids faible (dans un octet où seuls les 3 derniers bits sont utiles)
  shiftOut(DATA_PIN, SHIFT_CLK, MSBFIRST, (address & 0xFF));

  digitalWrite(LATCH_CLK, HIGH);  // Latch des données
}

// Fonction pour écrire un octet dans l'EEPROM
void writeEEPROM(uint16_t address, uint8_t data) {
  setAddress(address);

  // Mettre les données sur le bus
  for (int i = 0; i < 8; i++) {
    digitalWrite(DATA_BUS_START + i, (data >> i) & 0x01);
  }

  // Cycle d'écriture
  digitalWrite(WE_PIN, LOW);
  delayMicroseconds(1);  // Impulsion d'écriture
  digitalWrite(WE_PIN, HIGH);

  delay(5);  // Délai pour assurer la programmation
}

void loop() {
  Serial.println("Écriture de test à l'adresse 0x012 avec valeur 0xA5");
   for (uint16_t i = 0; i < 16; i++) {
    setAddress(1<<i);

    delay(300);
  }
}