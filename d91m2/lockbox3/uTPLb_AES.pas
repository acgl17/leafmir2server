{* ***** BEGIN LICENSE BLOCK *****
Copyright 2009, 2010 Sean B. Durkin
This file is part of TurboPower LockBox 3. TurboPower LockBox 3 is free
software being offered under a dual licensing scheme: LGPL3 or MPL1.1.

The contents of this file are subject to the Mozilla Public License (MPL)
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Alternatively, you may redistribute it and/or modify it under the terms of
the GNU Lesser General Public License (LGPL) as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

You should have received a copy of the Lesser GNU General Public License
along with TurboPower LockBox 3.  If not, see <http://www.gnu.org/licenses/>.

TurboPower LockBox is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. In relation to LGPL,
see the GNU Lesser General Public License for more details. In relation to MPL,
see the MPL License for the specific language governing rights and limitations
under the License.

The Initial Developer of the Original Code for TurboPower LockBox version 2
and earlier was TurboPower Software.

 * ***** END LICENSE BLOCK ***** *}

unit uTPLb_AES;
interface
uses Classes, uTPLb_BlockCipher, uTPLb_StreamCipher, uTPLb_Decorators;

type

{$IF compilerversion >= 211} [DesignDescription(
'From Wikipedia: QUOTE:'#13#10 +
'In cryptography, the Advanced Encryption Standard (AES) is a symmetric-key ' +
'encryption standard adopted by the U.S. government. The standard comprises ' +
'three block ciphers, AES-128, AES-192 and AES-256, adopted from a larger ' +
'collection originally published as Rijndael. Each of these ciphers has a ' +
'128-bit block size, with key  sizes of 128, 192 and 256 bits, respectively. ' +
'The AES ciphers have been analyzed extensively and are now used worldwide, ' +
'as was the case with its predecessor,[3] the Data Encryption Standard (DES).'#13#10 +
#13#10 +
'AES was announced by National Institute of Standards and Technology (NIST) ' +
'as U.S. FIPS PUB 197 (FIPS 197) on November 26, 2001 after a 5-year standa' +
'rdization process in which fifteen competing designs were presented and ' +
'evaluated before Rijndael was selected as the most suitable. It became ' +
'effective as a Federal government standard on May 26, 2002 after approval ' +
'by the Secretary of Commerce. AES is the first publicly accessible and open ' +
'cipher approved by the NSA for top secret information.'#13#10 +
'END QUOTE'
)] {$IFEND}
TAES = class( TInterfacedObject,
    IBlockCipher, ICryptoGraphicAlgorithm, IControlObject)
    // The IControlObject interface is necessary to support the Design
    //  Description.
  private
    FKeySize: integer; // Either 128, 192, or 256 bits.

    function  DisplayName: string;
    function  ProgId: string;
    function  Features: TAlgorithmicFeatureSet;
    function  DefinitionURL: string;
    function  WikipediaReference: string;
    function  SeedByteSize: integer; // Size that the input of the GenerateKey must be.
    function  GenerateKey( Seed: TStream): TSymetricKey;
    function  LoadKeyFromStream( Store: TStream): TSymetricKey;
    function  BlockSize: integer;  // in units of bits. Must be a multiple of 8.
    function  KeySize: integer;
    function  MakeBlockCodec( Key: TSymetricKey): IBlockCodec;
    function  SelfTest_Key: ansistring;
    function  SelfTest_Plaintext: ansistring;
    function  SelfTest_Ciphertext: ansistring;
    function  ControlObject: TObject;

  public
    constructor Create( KeySize1: integer);
  end;




implementation



uses SysUtils, uTPLb_IntegerUtils, uTPLb_I18n, uTPLb_Constants;


/// THE FOLLOWING FRAGMENT WAS GENERATED BY THE PRECOMPUTE PROGRAM.
///  BEGIN FRAGMENT +++
type
TMixColsFactor = (fx01, fx02, fx03, fx09, fx0b, fx0d, fx0e);

const
GF2_8_TimesTables: array [  TMixColsFactor, 0..255 ] of byte = (
( // fx01  --- Times 01 Table.
 $00, $01, $02, $03, $04, $05, $06, $07, $08, $09, $0A, $0B, $0C, $0D, $0E, $0F,
 $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $1A, $1B, $1C, $1D, $1E, $1F,
 $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $2A, $2B, $2C, $2D, $2E, $2F,
 $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $3A, $3B, $3C, $3D, $3E, $3F,
 $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4A, $4B, $4C, $4D, $4E, $4F,
 $50, $51, $52, $53, $54, $55, $56, $57, $58, $59, $5A, $5B, $5C, $5D, $5E, $5F,
 $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $6A, $6B, $6C, $6D, $6E, $6F,
 $70, $71, $72, $73, $74, $75, $76, $77, $78, $79, $7A, $7B, $7C, $7D, $7E, $7F,
 $80, $81, $82, $83, $84, $85, $86, $87, $88, $89, $8A, $8B, $8C, $8D, $8E, $8F,
 $90, $91, $92, $93, $94, $95, $96, $97, $98, $99, $9A, $9B, $9C, $9D, $9E, $9F,
 $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $A9, $AA, $AB, $AC, $AD, $AE, $AF,
 $B0, $B1, $B2, $B3, $B4, $B5, $B6, $B7, $B8, $B9, $BA, $BB, $BC, $BD, $BE, $BF,
 $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7, $C8, $C9, $CA, $CB, $CC, $CD, $CE, $CF,
 $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7, $D8, $D9, $DA, $DB, $DC, $DD, $DE, $DF,
 $E0, $E1, $E2, $E3, $E4, $E5, $E6, $E7, $E8, $E9, $EA, $EB, $EC, $ED, $EE, $EF,
 $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7, $F8, $F9, $FA, $FB, $FC, $FD, $FE, $FF
 ),

( // fx02  --- Times 02 Table.
 $00, $02, $04, $06, $08, $0A, $0C, $0E, $10, $12, $14, $16, $18, $1A, $1C, $1E,
 $20, $22, $24, $26, $28, $2A, $2C, $2E, $30, $32, $34, $36, $38, $3A, $3C, $3E,
 $40, $42, $44, $46, $48, $4A, $4C, $4E, $50, $52, $54, $56, $58, $5A, $5C, $5E,
 $60, $62, $64, $66, $68, $6A, $6C, $6E, $70, $72, $74, $76, $78, $7A, $7C, $7E,
 $80, $82, $84, $86, $88, $8A, $8C, $8E, $90, $92, $94, $96, $98, $9A, $9C, $9E,
 $A0, $A2, $A4, $A6, $A8, $AA, $AC, $AE, $B0, $B2, $B4, $B6, $B8, $BA, $BC, $BE,
 $C0, $C2, $C4, $C6, $C8, $CA, $CC, $CE, $D0, $D2, $D4, $D6, $D8, $DA, $DC, $DE,
 $E0, $E2, $E4, $E6, $E8, $EA, $EC, $EE, $F0, $F2, $F4, $F6, $F8, $FA, $FC, $FE,
 $1B, $19, $1F, $1D, $13, $11, $17, $15, $0B, $09, $0F, $0D, $03, $01, $07, $05,
 $3B, $39, $3F, $3D, $33, $31, $37, $35, $2B, $29, $2F, $2D, $23, $21, $27, $25,
 $5B, $59, $5F, $5D, $53, $51, $57, $55, $4B, $49, $4F, $4D, $43, $41, $47, $45,
 $7B, $79, $7F, $7D, $73, $71, $77, $75, $6B, $69, $6F, $6D, $63, $61, $67, $65,
 $9B, $99, $9F, $9D, $93, $91, $97, $95, $8B, $89, $8F, $8D, $83, $81, $87, $85,
 $BB, $B9, $BF, $BD, $B3, $B1, $B7, $B5, $AB, $A9, $AF, $AD, $A3, $A1, $A7, $A5,
 $DB, $D9, $DF, $DD, $D3, $D1, $D7, $D5, $CB, $C9, $CF, $CD, $C3, $C1, $C7, $C5,
 $FB, $F9, $FF, $FD, $F3, $F1, $F7, $F5, $EB, $E9, $EF, $ED, $E3, $E1, $E7, $E5
 ),

( // fx03  --- Times 03 Table.
 $00, $03, $06, $05, $0C, $0F, $0A, $09, $18, $1B, $1E, $1D, $14, $17, $12, $11,
 $30, $33, $36, $35, $3C, $3F, $3A, $39, $28, $2B, $2E, $2D, $24, $27, $22, $21,
 $60, $63, $66, $65, $6C, $6F, $6A, $69, $78, $7B, $7E, $7D, $74, $77, $72, $71,
 $50, $53, $56, $55, $5C, $5F, $5A, $59, $48, $4B, $4E, $4D, $44, $47, $42, $41,
 $C0, $C3, $C6, $C5, $CC, $CF, $CA, $C9, $D8, $DB, $DE, $DD, $D4, $D7, $D2, $D1,
 $F0, $F3, $F6, $F5, $FC, $FF, $FA, $F9, $E8, $EB, $EE, $ED, $E4, $E7, $E2, $E1,
 $A0, $A3, $A6, $A5, $AC, $AF, $AA, $A9, $B8, $BB, $BE, $BD, $B4, $B7, $B2, $B1,
 $90, $93, $96, $95, $9C, $9F, $9A, $99, $88, $8B, $8E, $8D, $84, $87, $82, $81,
 $9B, $98, $9D, $9E, $97, $94, $91, $92, $83, $80, $85, $86, $8F, $8C, $89, $8A,
 $AB, $A8, $AD, $AE, $A7, $A4, $A1, $A2, $B3, $B0, $B5, $B6, $BF, $BC, $B9, $BA,
 $FB, $F8, $FD, $FE, $F7, $F4, $F1, $F2, $E3, $E0, $E5, $E6, $EF, $EC, $E9, $EA,
 $CB, $C8, $CD, $CE, $C7, $C4, $C1, $C2, $D3, $D0, $D5, $D6, $DF, $DC, $D9, $DA,
 $5B, $58, $5D, $5E, $57, $54, $51, $52, $43, $40, $45, $46, $4F, $4C, $49, $4A,
 $6B, $68, $6D, $6E, $67, $64, $61, $62, $73, $70, $75, $76, $7F, $7C, $79, $7A,
 $3B, $38, $3D, $3E, $37, $34, $31, $32, $23, $20, $25, $26, $2F, $2C, $29, $2A,
 $0B, $08, $0D, $0E, $07, $04, $01, $02, $13, $10, $15, $16, $1F, $1C, $19, $1A
 ),

( // fx09  --- Times 09 Table.
 $00, $09, $12, $1B, $24, $2D, $36, $3F, $48, $41, $5A, $53, $6C, $65, $7E, $77,
 $90, $99, $82, $8B, $B4, $BD, $A6, $AF, $D8, $D1, $CA, $C3, $FC, $F5, $EE, $E7,
 $3B, $32, $29, $20, $1F, $16, $0D, $04, $73, $7A, $61, $68, $57, $5E, $45, $4C,
 $AB, $A2, $B9, $B0, $8F, $86, $9D, $94, $E3, $EA, $F1, $F8, $C7, $CE, $D5, $DC,
 $76, $7F, $64, $6D, $52, $5B, $40, $49, $3E, $37, $2C, $25, $1A, $13, $08, $01,
 $E6, $EF, $F4, $FD, $C2, $CB, $D0, $D9, $AE, $A7, $BC, $B5, $8A, $83, $98, $91,
 $4D, $44, $5F, $56, $69, $60, $7B, $72, $05, $0C, $17, $1E, $21, $28, $33, $3A,
 $DD, $D4, $CF, $C6, $F9, $F0, $EB, $E2, $95, $9C, $87, $8E, $B1, $B8, $A3, $AA,
 $EC, $E5, $FE, $F7, $C8, $C1, $DA, $D3, $A4, $AD, $B6, $BF, $80, $89, $92, $9B,
 $7C, $75, $6E, $67, $58, $51, $4A, $43, $34, $3D, $26, $2F, $10, $19, $02, $0B,
 $D7, $DE, $C5, $CC, $F3, $FA, $E1, $E8, $9F, $96, $8D, $84, $BB, $B2, $A9, $A0,
 $47, $4E, $55, $5C, $63, $6A, $71, $78, $0F, $06, $1D, $14, $2B, $22, $39, $30,
 $9A, $93, $88, $81, $BE, $B7, $AC, $A5, $D2, $DB, $C0, $C9, $F6, $FF, $E4, $ED,
 $0A, $03, $18, $11, $2E, $27, $3C, $35, $42, $4B, $50, $59, $66, $6F, $74, $7D,
 $A1, $A8, $B3, $BA, $85, $8C, $97, $9E, $E9, $E0, $FB, $F2, $CD, $C4, $DF, $D6,
 $31, $38, $23, $2A, $15, $1C, $07, $0E, $79, $70, $6B, $62, $5D, $54, $4F, $46
 ),

( // fx0B  --- Times 0B Table.
 $00, $0B, $16, $1D, $2C, $27, $3A, $31, $58, $53, $4E, $45, $74, $7F, $62, $69,
 $B0, $BB, $A6, $AD, $9C, $97, $8A, $81, $E8, $E3, $FE, $F5, $C4, $CF, $D2, $D9,
 $7B, $70, $6D, $66, $57, $5C, $41, $4A, $23, $28, $35, $3E, $0F, $04, $19, $12,
 $CB, $C0, $DD, $D6, $E7, $EC, $F1, $FA, $93, $98, $85, $8E, $BF, $B4, $A9, $A2,
 $F6, $FD, $E0, $EB, $DA, $D1, $CC, $C7, $AE, $A5, $B8, $B3, $82, $89, $94, $9F,
 $46, $4D, $50, $5B, $6A, $61, $7C, $77, $1E, $15, $08, $03, $32, $39, $24, $2F,
 $8D, $86, $9B, $90, $A1, $AA, $B7, $BC, $D5, $DE, $C3, $C8, $F9, $F2, $EF, $E4,
 $3D, $36, $2B, $20, $11, $1A, $07, $0C, $65, $6E, $73, $78, $49, $42, $5F, $54,
 $F7, $FC, $E1, $EA, $DB, $D0, $CD, $C6, $AF, $A4, $B9, $B2, $83, $88, $95, $9E,
 $47, $4C, $51, $5A, $6B, $60, $7D, $76, $1F, $14, $09, $02, $33, $38, $25, $2E,
 $8C, $87, $9A, $91, $A0, $AB, $B6, $BD, $D4, $DF, $C2, $C9, $F8, $F3, $EE, $E5,
 $3C, $37, $2A, $21, $10, $1B, $06, $0D, $64, $6F, $72, $79, $48, $43, $5E, $55,
 $01, $0A, $17, $1C, $2D, $26, $3B, $30, $59, $52, $4F, $44, $75, $7E, $63, $68,
 $B1, $BA, $A7, $AC, $9D, $96, $8B, $80, $E9, $E2, $FF, $F4, $C5, $CE, $D3, $D8,
 $7A, $71, $6C, $67, $56, $5D, $40, $4B, $22, $29, $34, $3F, $0E, $05, $18, $13,
 $CA, $C1, $DC, $D7, $E6, $ED, $F0, $FB, $92, $99, $84, $8F, $BE, $B5, $A8, $A3
 ),

( // fx0D  --- Times 0D Table.
 $00, $0D, $1A, $17, $34, $39, $2E, $23, $68, $65, $72, $7F, $5C, $51, $46, $4B,
 $D0, $DD, $CA, $C7, $E4, $E9, $FE, $F3, $B8, $B5, $A2, $AF, $8C, $81, $96, $9B,
 $BB, $B6, $A1, $AC, $8F, $82, $95, $98, $D3, $DE, $C9, $C4, $E7, $EA, $FD, $F0,
 $6B, $66, $71, $7C, $5F, $52, $45, $48, $03, $0E, $19, $14, $37, $3A, $2D, $20,
 $6D, $60, $77, $7A, $59, $54, $43, $4E, $05, $08, $1F, $12, $31, $3C, $2B, $26,
 $BD, $B0, $A7, $AA, $89, $84, $93, $9E, $D5, $D8, $CF, $C2, $E1, $EC, $FB, $F6,
 $D6, $DB, $CC, $C1, $E2, $EF, $F8, $F5, $BE, $B3, $A4, $A9, $8A, $87, $90, $9D,
 $06, $0B, $1C, $11, $32, $3F, $28, $25, $6E, $63, $74, $79, $5A, $57, $40, $4D,
 $DA, $D7, $C0, $CD, $EE, $E3, $F4, $F9, $B2, $BF, $A8, $A5, $86, $8B, $9C, $91,
 $0A, $07, $10, $1D, $3E, $33, $24, $29, $62, $6F, $78, $75, $56, $5B, $4C, $41,
 $61, $6C, $7B, $76, $55, $58, $4F, $42, $09, $04, $13, $1E, $3D, $30, $27, $2A,
 $B1, $BC, $AB, $A6, $85, $88, $9F, $92, $D9, $D4, $C3, $CE, $ED, $E0, $F7, $FA,
 $B7, $BA, $AD, $A0, $83, $8E, $99, $94, $DF, $D2, $C5, $C8, $EB, $E6, $F1, $FC,
 $67, $6A, $7D, $70, $53, $5E, $49, $44, $0F, $02, $15, $18, $3B, $36, $21, $2C,
 $0C, $01, $16, $1B, $38, $35, $22, $2F, $64, $69, $7E, $73, $50, $5D, $4A, $47,
 $DC, $D1, $C6, $CB, $E8, $E5, $F2, $FF, $B4, $B9, $AE, $A3, $80, $8D, $9A, $97
 ),

( // fx0E  --- Times 0E Table.
 $00, $0E, $1C, $12, $38, $36, $24, $2A, $70, $7E, $6C, $62, $48, $46, $54, $5A,
 $E0, $EE, $FC, $F2, $D8, $D6, $C4, $CA, $90, $9E, $8C, $82, $A8, $A6, $B4, $BA,
 $DB, $D5, $C7, $C9, $E3, $ED, $FF, $F1, $AB, $A5, $B7, $B9, $93, $9D, $8F, $81,
 $3B, $35, $27, $29, $03, $0D, $1F, $11, $4B, $45, $57, $59, $73, $7D, $6F, $61,
 $AD, $A3, $B1, $BF, $95, $9B, $89, $87, $DD, $D3, $C1, $CF, $E5, $EB, $F9, $F7,
 $4D, $43, $51, $5F, $75, $7B, $69, $67, $3D, $33, $21, $2F, $05, $0B, $19, $17,
 $76, $78, $6A, $64, $4E, $40, $52, $5C, $06, $08, $1A, $14, $3E, $30, $22, $2C,
 $96, $98, $8A, $84, $AE, $A0, $B2, $BC, $E6, $E8, $FA, $F4, $DE, $D0, $C2, $CC,
 $41, $4F, $5D, $53, $79, $77, $65, $6B, $31, $3F, $2D, $23, $09, $07, $15, $1B,
 $A1, $AF, $BD, $B3, $99, $97, $85, $8B, $D1, $DF, $CD, $C3, $E9, $E7, $F5, $FB,
 $9A, $94, $86, $88, $A2, $AC, $BE, $B0, $EA, $E4, $F6, $F8, $D2, $DC, $CE, $C0,
 $7A, $74, $66, $68, $42, $4C, $5E, $50, $0A, $04, $16, $18, $32, $3C, $2E, $20,
 $EC, $E2, $F0, $FE, $D4, $DA, $C8, $C6, $9C, $92, $80, $8E, $A4, $AA, $B8, $B6,
 $0C, $02, $10, $1E, $34, $3A, $28, $26, $7C, $72, $60, $6E, $44, $4A, $58, $56,
 $37, $39, $2B, $25, $0F, $01, $13, $1D, $47, $49, $5B, $55, $7F, $71, $63, $6D,
 $D7, $D9, $CB, $C5, $EF, $E1, $F3, $FD, $A7, $A9, $BB, $B5, $9F, $91, $83, $8D
 )
                                                                 );
///  END FRAGMENT ---

type
TMatrix = array[ {product byte index:}0..3,
                 {factor  byte index:}0..3 ] of TMixColsFactor;

const
  MixColumsMatrix: TMatrix = (  // Refer page 18 of the standard.
    (fx02, fx03, fx01, fx01),
    (fx01, fx02, fx03, fx01),
    (fx01, fx01, fx02, fx03),
    (fx03, fx01, fx01, fx02));

  InvMixColumsMatrix: TMatrix = (  // Refer page 23 of the standard.
    (fx0e, fx0b, fx0d, fx09),
    (fx09, fx0e, fx0b, fx0d),
    (fx0d, fx09, fx0e, fx0b),
    (fx0b, fx0d, fx09, fx0e));


const S_Box: array[ 0..255 ] of byte = (
  $63, $7c, $77, $7b, $f2, $6b, $6f, $c5, $30, $01, $67, $2b, $fe, $d7, $ab, $76,
  $ca, $82, $c9, $7d, $fa, $59, $47, $f0, $ad, $d4, $a2, $af, $9c, $a4, $72, $c0,
  $b7, $fd, $93, $26, $36, $3f, $f7, $cc, $34, $a5, $e5, $f1, $71, $d8, $31, $15,
  $04, $c7, $23, $c3, $18, $96, $05, $9a, $07, $12, $80, $e2, $eb, $27, $b2, $75,
  $09, $83, $2c, $1a, $1b, $6e, $5a, $a0, $52, $3b, $d6, $b3, $29, $e3, $2f, $84,
  $53, $d1, $00, $ed, $20, $fc, $b1, $5b, $6a, $cb, $be, $39, $4a, $4c, $58, $cf,
  $d0, $ef, $aa, $fb, $43, $4d, $33, $85, $45, $f9, $02, $7f, $50, $3c, $9f, $a8,
  $51, $a3, $40, $8f, $92, $9d, $38, $f5, $bc, $b6, $da, $21, $10, $ff, $f3, $d2,
  $cd, $0c, $13, $ec, $5f, $97, $44, $17, $c4, $a7, $7e, $3d, $64, $5d, $19, $73,
  $60, $81, $4f, $dc, $22, $2a, $90, $88, $46, $ee, $b8, $14, $de, $5e, $0b, $db,
  $e0, $32, $3a, $0a, $49, $06, $24, $5c, $c2, $d3, $ac, $62, $91, $95, $e4, $79,
  $e7, $c8, $37, $6d, $8d, $d5, $4e, $a9, $6c, $56, $f4, $ea, $65, $7a, $ae, $08,
  $ba, $78, $25, $2e, $1c, $a6, $b4, $c6, $e8, $dd, $74, $1f, $4b, $bd, $8b, $8a,
  $70, $3e, $b5, $66, $48, $03, $f6, $0e, $61, $35, $57, $b9, $86, $c1, $1d, $9e,
  $e1, $f8, $98, $11, $69, $d9, $8e, $94, $9b, $1e, $87, $e9, $ce, $55, $28, $df,
  $8c, $a1, $89, $0d, $bf, $e6, $42, $68, $41, $99, $2d, $0f, $b0, $54, $bb, $16);

var InvS_Box: array[ 0..255 ] of byte;


procedure InitUnit_AES;
var
  Idx: byte;
begin
for Idx := 0 to 255 do
  InvS_Box[ S_Box[ Idx]] := Idx
end;


procedure DoneUnit_AES;
begin
end;


function MulVector( const Matrix: TMatrix; Vector: uint32): uint32;
var
  Row, Col: integer;
  Temp: byte;
begin
for Row := 0 to 3 do
  begin
  Temp := 0;
  for Col := 0 to 3 do
    Temp := Temp xor GF2_8_TimesTables[
                        Matrix[ Row, Col],
                        longrec( Vector).Bytes[ Col]
                                       ];
  longrec( result).Bytes[ Row] := Temp
  end
end;



type
TAESKey = class( TSymetricKey)
  private
    FKeySize: integer;   // 128, 192 or 256
    Nk: integer;         // 4, 6 or 8
    Nr: integer;         // 10, 12 or 14
    FCols: integer;      // = Nb * (Nr+1) = 44, 52, 60
    w: array [ 0 .. 59 ] of uint32;  // Logical length is 0 .. Nb*(Nr+1)-1

    procedure ExpandKey;

  public
    constructor Create( GenSeed: TStream; AES1: TAES);
    constructor LoadFromStream( Store: TStream; AES1: TAES);
    destructor  Destroy; override;

    procedure   SaveToStream( Stream: TStream);     override;
    procedure   Burn;   override;
  end;


TAESBlockCodec = class( TInterfacedObject, IBlockCodec)
  private
    FCipher: TAES;
    FKey: TAESKey;
    State: array[ 0..3 ] of uint32;
    Nr: integer;

    procedure MulMatrix( const Matrix: TMatrix);
    procedure Shift3rdRow;

    procedure Encrypt_Block( Plaintext{in}, Ciphertext{out}: TMemoryStream);
    procedure Decrypt_Block( Plaintext{out}, Ciphertext{in}: TMemoryStream);
    procedure Reset;
    procedure Burn;

    procedure AddRoundKey( Column: integer);
    procedure SubBytes;
    procedure ShiftRows;
    procedure MixColumns;

    procedure InvSubBytes;
    procedure InvShiftRows;
    procedure InvMixColumns;

    constructor Create( Cipher1: TAES; Key1: TAESKey);
    destructor  Destroy; override;
  end;



{ TAES }

function TAES.BlockSize: integer;
begin
result := 128
end;



function TAES.ControlObject: TObject;
begin
result := self
end;


constructor TAES.Create( KeySize1: integer);
begin
FKeySize := KeySize1;
if (FKeySize <> 128) and (FKeySize <> 192) and (FKeySize <> 256) then
  raise Exception.Create( 'Invalid key size for AES.')
end;




function TAES.DefinitionURL: string;
begin
result := 'http://www.csrc.nist.gov/publications/fips/fips197/fips-197.pdf'
end;




function TAES.DisplayName: string;
begin
result := 'AES-%d'
end;



function TAES.Features: TAlgorithmicFeatureSet;
begin
result := [afOpenSourceSoftware, afDisplayNameOnKeySize];
if FKeySize = 256 then
  Include( result, afStar)
end;



function TAES.KeySize: integer;
begin
result := FKeySize
end;


function TAES.ProgId: string;
begin
result := Format( AES_ProgId, [FKeySize])
end;


function TAES.SeedByteSize: integer;
begin
result := FKeySize div 8
end;


function TAES.SelfTest_Key: ansistring;  // Refer appendix C.
begin
case FKeySize of
  128: result := '000102030405060708090a0b0c0d0e0f';
  192: result := '000102030405060708090a0b0c0d0e0f1011121314151617';
  256: result := '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f';
  end
end;


function TAES.SelfTest_Plaintext: ansistring; // Refer appendix C.
begin
result := '00112233445566778899aabbccddeeff'
end;


function TAES.SelfTest_Ciphertext: ansistring;  // Refer appendix C.
begin
case FKeySize of
  128: result := '69c4e0d86a7b0430d8cdb78070b4c55a';
  192: result := 'dda97ca4864cdfe06eaf70a0ec0d7191';
  256: result := '8ea2b7ca516745bfeafc49904b496089';
  end;
end;

function TAES.WikipediaReference: string;
begin
result := 'Advanced_Encryption_Standard'
end;


function TAES.GenerateKey( Seed: TStream): TSymetricKey;
begin
result := TAESKey.Create( Seed, self)
end;


function TAES.LoadKeyFromStream( Store: TStream): TSymetricKey;
begin
result := TAESKey.LoadFromStream( Store, self)
end;


function TAES.MakeBlockCodec( Key: TSymetricKey): IBlockCodec;
begin
result := TAESBlockCodec.Create( self, Key as TAESKey)
end;



{ TAESKey }

procedure TAESKey.Burn;
begin
FillChar( w, SizeOf( W), 0)
end;


//const usingTestVectors = False;

constructor TAESKey.Create( GenSeed: TStream; AES1: TAES);
begin
FKeySize := AES1.FKeySize; // 128, 192 or 256
case FKeySize of
  128: begin Nk := 4; Nr := 10 end;
  192: begin Nk := 6; Nr := 12 end;
  256: begin Nk := 8; Nr := 14 end;
  end;
FCols := 4 * (Nr+1); // 44, 52, 60
GenSeed.ReadBuffer( w, FKeySize div 8);
{if usingTestVectors then
  begin
  case FKeySize of
    128: begin
         w[0] := $16157e2b;  // In appendix A, this is written as bigendien,
                             // but our integers are little-endien so this source
                             // appears to reverse the byte order.
         w[1] := $a6d2ae28;
         w[2] := $8815f7ab;
         w[3] := $3c4fcf09;
         end;
    192: begin
         w[0] := $f7b0738e;
         w[1] := $52640eda;
         w[2] := $2bf310c8;
         w[3] := $e5799080;
         w[4] := $d2eaf862;
         w[5] := $7b6b2c52;
         end;
    256: begin
         w[0] := $10eb3d60;
         w[1] := $be71ca15;
         w[2] := $f0ae732b;
         w[3] := $81777d85;
         w[4] := $072c351f;
         w[5] := $d708613b;
         w[6] := $a310982d;
         w[7] := $f4df1409;
         end;
    end;
  end;  }
ExpandKey
end;



destructor TAESKey.Destroy;
begin
Burn;
inherited
end;



function SubWord( Value: uint32): uint32;
var
  j: integer;
begin
for j := 0 to 3 do
  longrec( result).Bytes[j] := S_Box[ longrec( Value).Bytes[j]]
end;

function InvSubWord( Value: uint32): uint32;
var
  j: integer;
begin
for j := 0 to 3 do
  longrec( result).Bytes[j] := InvS_Box[ longrec( Value).Bytes[j]]
end;

const Rcon: array[ 1..10 ] of uint32 = (
  $00000001,  // In big-endien this is 0x01000000
  $00000002,
  $00000004,
  $00000008,
  $00000010,
  $00000020,
  $00000040,
  $00000080,
  $0000001b,
  $00000036);

procedure TAESKey.ExpandKey;
var
  i: integer;
  Temp: uint32;
  SubWord_Frequency: integer;
  isNewExpandRound: boolean;
begin
if FKeySize <> 256 then
    SubWord_Frequency := Nk
  else
    SubWord_Frequency := 4;
for i := Nk to FCols - 1 do
  begin
  Temp := w[ i - 1 ];
  isNewExpandRound := (i mod Nk) = 0;
  if isNewExpandRound then
    Temp := (Temp shr 8) or (Temp shl 24);
  if (i mod SubWord_Frequency) = 0 then
    Temp := SubWord( Temp) ;
  if isNewExpandRound then
    Temp := Temp XOR Rcon[ i div Nk ];
  w[i] := Temp XOR w[ i - Nk ]
  end
end;



constructor TAESKey.LoadFromStream( Store: TStream; AES1: TAES);
begin
FKeySize := AES1.FKeySize; // 128, 192 or 256
case FKeySize of
  128: begin Nk := 4; Nr := 10 end;
  192: begin Nk := 6; Nr := 12 end;
  256: begin Nk := 8; Nr := 14 end;
  end;
FCols := 4 * (Nr+1); // 44, 52, 60
Store.ReadBuffer( w, FKeySize div 8);
ExpandKey
end;



procedure TAESKey.SaveToStream( Stream: TStream);
begin
Stream.WriteBuffer( w, FKeySize div 8)
end;


{ TAESBlockCodec }

procedure TAESBlockCodec.Burn;
begin
FillChar( State, SizeOf( State), 0)
end;




constructor TAESBlockCodec.Create( Cipher1: TAES; Key1: TAESKey);
begin
FCipher := Cipher1;
FKey := Key1;
FillChar( State, SizeOf( State), 0);
case FKey.FKeySize of
  128: Nr := 10;
  192: Nr := 12;
  256: Nr := 14;
  end
end;




procedure TAESBlockCodec.Encrypt_Block( Plaintext, Ciphertext: TMemoryStream);
var
  i: integer;
begin
Plaintext.Position := 0;
Plaintext.Read( State, SizeOf( State));
AddRoundKey( 0);
for i := 1 to Nr do
  begin
  SubBytes;
  ShiftRows;
  if i <> Nr then
    MixColumns;
  AddRoundKey( i * 4)
  end;
Ciphertext.Position := 0;
Ciphertext.Write( State, SizeOf( State))
end;



procedure TAESBlockCodec.Decrypt_Block( Plaintext, Ciphertext: TMemoryStream);
var
  i: integer;
begin
Ciphertext.Position := 0;
Ciphertext.Read( State, SizeOf( State));
for i := Nr downto 1 do
  begin
  AddRoundKey( i * 4);
  if i <> Nr then
    InvMixColumns;
  InvShiftRows;
  InvSubBytes
  end;
AddRoundKey( 0);
Plaintext.Position := 0;
Plaintext.Write( State, SizeOf( State))
end;




destructor TAESBlockCodec.Destroy;
begin
Burn;
inherited
end;

procedure TAESBlockCodec.Reset;
begin
end;


procedure TAESBlockCodec.AddRoundKey( Column: integer);
var
  j: integer;
begin
for j := 0 to 3 do
  State[j] := State[j] XOR FKey.w[ Column + j]
end;



procedure TAESBlockCodec.MulMatrix( const Matrix: TMatrix);
var
  j: integer;
begin
for j := 0 to 3 do
  State[j] := MulVector( Matrix, State[ j])
end;


procedure TAESBlockCodec.MixColumns;
begin
MulMatrix( MixColumsMatrix)
end;


procedure TAESBlockCodec.InvMixColumns;
begin
MulMatrix( InvMixColumsMatrix)
end;



procedure TAESBlockCodec.InvSubBytes;
var
  j: integer;
begin
for j := 0 to 3 do
  State[j] := InvSubWord( State[j])
end;


procedure TAESBlockCodec.Shift3rdRow;
var
  Mask, Temp: uint32;
begin
Mask := $00FF0000; // 3rd byte.
Temp := State[0] and Mask;
State[0] := (State[0] and (not Mask)) or (State[2] and Mask);
State[2] := (State[2] and (not Mask)) or Temp;
Temp := State[1] and Mask;
State[1] := (State[1] and (not Mask)) or (State[3] and Mask);
State[3] := (State[3] and (not Mask)) or Temp;
end;


procedure TAESBlockCodec.ShiftRows;
var
  j: integer;
  Mask, Temp: uint32;
begin
// Shift 2nd row left.
Mask := $0000FF00; // 2nd LS byte.
Temp := State[0] and Mask;
for j := 0 to 2 do
  State[j] := (State[j] and (not Mask)) or (State[j+1] and Mask);
State[3] := (State[3] and (not Mask)) or Temp;
Shift3rdRow;
// Shift 4th row right.
Mask := $FF000000; // MS byte.
Temp := State[3] and Mask;
for j := 3 downto 1 do
  State[j] := (State[j] and (not Mask)) or (State[j-1] and Mask);
State[0] := (State[0] and (not Mask)) or Temp
end;


procedure TAESBlockCodec.InvShiftRows;
var
  j: integer;
  Mask, Temp: uint32;
begin
// Shift 2nd row right.
Mask := $0000FF00; // 2nd LS byte.
Temp := State[3] and Mask;
for j := 3 downto 1 do
  State[j] := (State[j] and (not Mask)) or (State[j-1] and Mask);
State[0] := (State[0] and (not Mask)) or Temp;
Shift3rdRow;
// Shift 4th row left.
Mask := $FF000000; // MS byte.
Temp := State[0] and Mask;
for j := 0 to 2 do
  State[j] := (State[j] and (not Mask)) or (State[j+1] and Mask);
State[3] := (State[3] and (not Mask)) or Temp
end;


procedure TAESBlockCodec.SubBytes;
var
  j: integer;
begin
for j := 0 to 3 do
  State[j] := SubWord( State[j])
end;



initialization
InitUnit_AES;

finalization
DoneUnit_AES;

end.
