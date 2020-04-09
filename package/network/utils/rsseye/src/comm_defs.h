#ifndef _commdefs_
#define _commdefs_

typedef uint8_t tChannelNumber;

typedef uint8_t tChannel;

typedef enum Bandwidth
{
  BW_10MHz,
  BW_20MHz
} eBandwidth;
typedef uint8_t tBandwidth;

typedef enum ModulationCodingScheme
{
  /// Rate 1/2 BPSK
  ModulationCodingScheme_R12BPSK = 0xB,
  /// Rate 3/4 BPSK
  ModulationCodingScheme_R34BPSK = 0xF,
  /// Rate 1/2 QPSK
  ModulationCodingScheme_R12QPSK = 0xA,
  /// Rate 3/4 QPSK
  ModulationCodingScheme_R34QPSK = 0xE,
  /// Rate 1/2 16QAM
  ModulationCodingScheme_R12QAM16 = 0x9,
  /// Rate 3/4 16QAM
  ModulationCodingScheme_R34QAM16 = 0xD,
  /// Rate 2/3 64QAM
  ModulationCodingScheme_R23QAM64 = 0x8,
  /// Rate 3/4 64QAM
  ModulationCodingScheme_R34QAM64 = 0xC,
  /// Use default data rate
  ModulationCodingScheme_DEFAULT = 0x0,
  /// Use transmit rate control
  ModulationCodingScheme_TRC = 0x1,
} eModulationCodingScheme;
typedef uint8_t tModulationCodingScheme;

typedef int16_t tPower;

typedef enum TxPwrCtl
{
  TPC_MANUAL,
  TPC_DEFAULT,
  TPC_TPC
} eTxPwrCtl;
typedef uint8_t tTxPwrCtl;

typedef struct TxPower
{
  tTxPwrCtl PowerSetting;
  tPower ManualPower;
}__attribute__ ((packed)) tTxPower;

typedef enum TxAntenna
{
  _TXANT_DEFAULT = 0,
  _TXANT_ANTENNA1 = 1,
  _TXANT_ANTENNA2 = 2,
  _TXANT_ANTENNA1AND2 = 3
} eTxAntenna;
typedef uint8_t tTxAntenna;

typedef uint8_t tMyMACAddress[6];

/**
 *  Priority
 */
typedef enum Priority
{
  _PRIO_0 = 0,
  _PRIO_1 = 1,
  _PRIO_2 = 2,
  _PRIO_3 = 3,
  _PRIO_4 = 4,
  _PRIO_5 = 5,
  _PRIO_6 = 6,
  _PRIO_7 = 7,
} ePriority;
typedef uint8_t tPriority;

typedef enum Service
{
  _QOS_ACK = 0x00,
  _QOS_NOACK = 0x01
} eService;
typedef uint8_t tService;

#endif
