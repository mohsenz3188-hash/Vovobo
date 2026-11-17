import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MohsenPlcApp());
}

class MohsenPlcApp extends StatelessWidget {
  const MohsenPlcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOHSEN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFECEFF1),
        primaryColor: const Color(0xFF00695C),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF00695C),
          secondary: Color(0xFFE65100),
          surface: Colors.white,
        ),
      ),
      home: const PlcWorkspaceScreen(),
    );
  }
}

enum BlockCategory { co, gf, sfTimer, sfCounter, sfAnalog, sfMisc }

enum EquipmentType { motor, lamp, pump, gate }

enum BlockType {
  input,
  analogInput,
  output,
  analogOutput,
  flag,
  high,
  low,
  andGate,
  andEdge,
  orGate,
  nandGate,
  norGate,
  xorGate,
  notGate,
  ton,
  tof,
  tonr,
  tp,
  pulse,
  stairway,
  weeklyTimer,
  yearlyTimer,
  ctud,
  hoursCounter,
  analogCmp,
  analogAmp,
  analogMath,
  piController,
  rs,
  impulse,
  shiftRegister,
  messageText,
}

extension BlockTypeInfo on BlockType {
  BlockCategory get category {
    switch (this) {
      case BlockType.input:
      case BlockType.analogInput:
      case BlockType.output:
      case BlockType.analogOutput:
      case BlockType.flag:
      case BlockType.high:
      case BlockType.low:
        return BlockCategory.co;
      case BlockType.andGate:
      case BlockType.andEdge:
      case BlockType.orGate:
      case BlockType.nandGate:
      case BlockType.norGate:
      case BlockType.xorGate:
      case BlockType.notGate:
        return BlockCategory.gf;
      case BlockType.ton:
      case BlockType.tof:
      case BlockType.tonr:
      case BlockType.tp:
      case BlockType.pulse:
      case BlockType.stairway:
      case BlockType.weeklyTimer:
      case BlockType.yearlyTimer:
        return BlockCategory.sfTimer;
      case BlockType.ctud:
      case BlockType.hoursCounter:
        return BlockCategory.sfCounter;
      case BlockType.analogCmp:
      case BlockType.analogAmp:
      case BlockType.analogMath:
      case BlockType.piController:
        return BlockCategory.sfAnalog;
      case BlockType.rs:
      case BlockType.impulse:
      case BlockType.shiftRegister:
      case BlockType.messageText:
        return BlockCategory.sfMisc;
    }
  }

  String get shortName {
    switch (this) {
      case BlockType.input:
        return 'I';
      case BlockType.analogInput:
        return 'AI';
      case BlockType.output:
        return 'Q';
      case BlockType.analogOutput:
        return 'AQ';
      case BlockType.flag:
        return 'M';
      case BlockType.high:
        return 'HI';
      case BlockType.low:
        return 'LO';
      case BlockType.andGate:
        return '&';
      case BlockType.andEdge:
        return '&↑';
      case BlockType.orGate:
        return '≥1';
      case BlockType.nandGate:
        return '&!';
      case BlockType.norGate:
        return '≥1!';
      case BlockType.xorGate:
        return '=1';
      case BlockType.notGate:
        return '1';
      case BlockType.ton:
        return 'T';
      case BlockType.tof:
        return 'T';
      case BlockType.tonr:
        return 'T!';
      case BlockType.tp:
        return 'TP';
      case BlockType.pulse:
        return '⊓⊔';
      case BlockType.stairway:
        return '⏚';
      case BlockType.weeklyTimer:
        return '📅';
      case BlockType.yearlyTimer:
        return '📆';
      case BlockType.ctud:
        return 'C±';
      case BlockType.hoursCounter:
        return '⏱';
      case BlockType.analogCmp:
        return 'A≥';
      case BlockType.analogAmp:
        return 'A×';
      case BlockType.analogMath:
        return 'A+';
      case BlockType.piController:
        return 'PI';
      case BlockType.rs:
        return 'RS';
      case BlockType.impulse:
        return '⏠';
      case BlockType.shiftRegister:
        return '>>';
      case BlockType.messageText:
        return 'TXT';
    }
  }

  String get title {
    switch (this) {
      case BlockType.input:
        return 'Input (I)';
      case BlockType.analogInput:
        return 'Analog In (AI)';
      case BlockType.output:
        return 'Output (Q)';
      case BlockType.analogOutput:
        return 'Analog Out (AQ)';
      case BlockType.flag:
        return 'Flag (M)';
      case BlockType.high:
        return 'High (1)';
      case BlockType.low:
        return 'Low (0)';
      case BlockType.andGate:
        return 'AND';
      case BlockType.andEdge:
        return 'AND (Edge)';
      case BlockType.orGate:
        return 'OR';
      case BlockType.nandGate:
        return 'NAND';
      case BlockType.norGate:
        return 'NOR';
      case BlockType.xorGate:
        return 'XOR';
      case BlockType.notGate:
        return 'NOT';
      case BlockType.ton:
        return 'On-Delay (TON)';
      case BlockType.tof:
        return 'Off-Delay (TOF)';
      case BlockType.tonr:
        return 'Retentive On';
      case BlockType.tp:
        return 'Wiping Relay';
      case BlockType.pulse:
        return 'Async Pulse';
      case BlockType.stairway:
        return 'Stairway Light';
      case BlockType.weeklyTimer:
        return 'Weekly Timer';
      case BlockType.yearlyTimer:
        return 'Yearly Timer';
      case BlockType.ctud:
        return 'Up/Dn Counter';
      case BlockType.hoursCounter:
        return 'Hours Counter';
      case BlockType.analogCmp:
        return 'Analog Thresh';
      case BlockType.analogAmp:
        return 'Analog Amp';
      case BlockType.analogMath:
        return 'Analog Math';
      case BlockType.piController:
        return 'PI Controller';
      case BlockType.rs:
        return 'Latching (RS)';
      case BlockType.impulse:
        return 'Impulse Relay';
      case BlockType.shiftRegister:
        return 'Shift Register';
      case BlockType.messageText:
        return 'Message Text';
    }
  }

  int get inputCount {
    switch (this) {
      case BlockType.input:
      case BlockType.analogInput:
      case BlockType.high:
      case BlockType.low:
      case BlockType.weeklyTimer:
      case BlockType.yearlyTimer:
        return 0;
      case BlockType.output:
      case BlockType.analogOutput:
      case BlockType.flag:
      case BlockType.notGate:
      case BlockType.ton:
      case BlockType.tof:
      case BlockType.tp:
      case BlockType.pulse:
      case BlockType.stairway:
      case BlockType.analogCmp:
      case BlockType.analogAmp:
      case BlockType.messageText:
        return 1;
      case BlockType.xorGate:
      case BlockType.tonr:
      case BlockType.rs:
      case BlockType.impulse:
      case BlockType.hoursCounter:
      case BlockType.analogMath:
      case BlockType.piController:
      case BlockType.shiftRegister:
        return 2;
      case BlockType.andGate:
      case BlockType.andEdge:
      case BlockType.orGate:
      case BlockType.nandGate:
      case BlockType.norGate:
      case BlockType.ctud:
        return 3;
    }
  }

  bool get hasOutput =>
      this != BlockType.output &&
      this != BlockType.analogOutput &&
      this != BlockType.messageText;

  List<String> get pinLabels {
    switch (this) {
      case BlockType.rs:
        return ['S', 'R'];
      case BlockType.impulse:
      case BlockType.tonr:
        return ['Trg', 'R'];
      case BlockType.ctud:
        return ['Cnt', 'Dir', 'R'];
      case BlockType.hoursCounter:
        return ['En', 'R'];
      case BlockType.shiftRegister:
        return ['In', 'Trg'];
      case BlockType.analogMath:
        return ['A1', 'A2'];
      case BlockType.piController:
        return ['PV', 'En'];
      case BlockType.ton:
      case BlockType.tof:
      case BlockType.tp:
      case BlockType.pulse:
      case BlockType.stairway:
        return ['Trg'];
      case BlockType.analogCmp:
      case BlockType.analogAmp:
      case BlockType.analogOutput:
        return ['Ax'];
      case BlockType.messageText:
        return ['En'];
      default:
        return List.generate(inputCount, (i) => '${i + 1}');
    }
  }

  Color get logoBodyColor => const Color(0xFFE5C158);
}

class PlcBlock {
  final String id;
  final String blockCode;
  final BlockType type;
  String label;
  double x;
  double y;
  bool value;
  double param;
  double param2;
  double elapsed;
  double analogVal;
  bool prevClk;
  bool isToggle;
  String messageText;
  double powerWatts;
  EquipmentType equipmentType;

  PlcBlock({
    required this.id,
    this.blockCode = 'B001',
    required this.type,
    required this.label,
    required this.x,
    required this.y,
    this.value = false,
    this.param = 3.0,
    this.param2 = 2.0,
    this.elapsed = 0.0,
    this.analogVal = 0.0,
    this.prevClk = false,
    this.isToggle = true,
    this.messageText = 'LOGO! SYSTEM READY',
    this.powerWatts = 100.0,
    this.equipmentType = EquipmentType.lamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': blockCode,
        'type': type.name,
        'label': label,
        'x': x,
        'y': y,
        'param': param,
        'param2': param2,
        'isToggle': isToggle,
        'messageText': messageText,
        'powerWatts': powerWatts,
        'equipmentType': equipmentType.name,
      };

  factory PlcBlock.fromJson(Map<String, dynamic> j) => PlcBlock(
        id: j['id'],
        blockCode: j['code'] ?? 'B001',
        type: BlockType.values.firstWhere((e) => e.name == j['type']),
        label: j['label'],
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        param: (j['param'] as num?)?.toDouble() ?? 3.0,
        param2: (j['param2'] as num?)?.toDouble() ?? 2.0,
        isToggle: j['isToggle'] ?? true,
        messageText: j['messageText'] ?? 'LOGO! SYSTEM READY',
        powerWatts: (j['powerWatts'] as num?)?.toDouble() ?? 100.0,
        equipmentType: EquipmentType.values.firstWhere(
          (e) => e.name == (j['equipmentType'] ?? 'lamp'),
          orElse: () => EquipmentType.lamp,
        ),
      );
}

class PlcWire {
  final String id;
  final String fromBlockId;
  final String toBlockId;
  final int toPinIndex;

  PlcWire({
    required this.id,
    required this.fromBlockId,
    required this.toBlockId,
    required this.toPinIndex,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': fromBlockId,
        'to': toBlockId,
        'pin': toPinIndex,
      };

  factory PlcWire.fromJson(Map<String, dynamic> j) => PlcWire(
        id: j['id'],
        fromBlockId: j['from'],
        toBlockId: j['to'],
        toPinIndex: j['pin'],
      );
}

abstract class LadNode {
  bool isActive(Map<String, PlcBlock> map);
}

class LadContact extends LadNode {
  final String blockId;
  final String label;
  final bool inverted;
  LadContact(this.blockId, this.label, {this.inverted = false});

  @override
  bool isActive(Map<String, PlcBlock> map) {
    final val = map[blockId]?.value ?? false;
    return inverted ? !val : val;
  }
}

class LadSeries extends LadNode {
  final List<LadNode> items;
  LadSeries(this.items);
  @override
  bool isActive(Map<String, PlcBlock> map) =>
      items.isNotEmpty && items.every((e) => e.isActive(map));
}

class LadParallel extends LadNode {
  final List<LadNode> branches;
  LadParallel(this.branches);
  @override
  bool isActive(Map<String, PlcBlock> map) =>
      branches.any((e) => e.isActive(map));
}

class LadRung {
  final String coilLabel;
  final PlcBlock targetBlock;
  final LadNode? condition;
  LadRung({
    required this.coilLabel,
    required this.targetBlock,
    required this.condition,
  });
}

class PlcWorkspaceScreen extends StatefulWidget {
  const PlcWorkspaceScreen({super.key});

  @override
  State<PlcWorkspaceScreen> createState() => _PlcWorkspaceScreenState();
}

class _PlcWorkspaceScreenState extends State<PlcWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  static const double blockWidth = 84.0;
  static const double blockHeight = 64.0;

  final GlobalKey _canvasRepaintKey = GlobalKey();

  List<PlcBlock> blocks = [];
  List<PlcWire> wires = [];
  final List<Map<String, bool>> scopeHistory = [];
  final Map<String, double> tankLevels = {};
  final Map<String, double> gatePositions = {};

  bool isSimulating = false;
  bool isPowerOutage = false;
  bool showTreeSidebar = true;
  bool isWireTool = false;
  Offset? dragWireStart;
  Offset? dragWireCurrent;
  String? dragFromBlockId;
  int viewMode = 0; // 0: FBD, 1: LAD, 2: SCOPE, 3: PLANT (کارگاهی)
  double simHour = 19.0;
  Timer? _simTimer;
  String? selectedOutputBlockId;
  int _idCounter = 1;
  late AnimationController _motorAnim;

  @override
  void initState() {
    super.initState();
    _motorAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _loadTemplate('p1_multi_switch');
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _motorAnim.dispose();
    super.dispose();
  }

  String _nextId(String prefix) => '${prefix}_${_idCounter++}';

  void _toggleSimulation() {
    setState(() {
      isSimulating = !isSimulating;
      isPowerOutage = false;
      selectedOutputBlockId = null;
      if (isSimulating) {
        scopeHistory.clear();
        for (final b in blocks) {
          if (b.type != BlockType.input && b.type != BlockType.analogInput) {
            b.value = (b.type == BlockType.high);
            b.elapsed = 0.0;
            b.prevClk = false;
          }
        }
        _simTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          _evaluateCycle(0.1);
        });
      } else {
        _simTimer?.cancel();
        _simTimer = null;
        for (final b in blocks) {
          b.value = false;
          b.elapsed = 0.0;
          b.prevClk = false;
        }
      }
    });
  }

  void _togglePowerOutage() {
    if (!isSimulating) return;
    setState(() {
      isPowerOutage = !isPowerOutage;
      if (isPowerOutage) {
        // Non-retentive blocks reset on power failure; TONR, CTUD, OT keep elapsed!
        for (final b in blocks) {
          if (b.type != BlockType.tonr &&
              b.type != BlockType.ctud &&
              b.type != BlockType.hoursCounter) {
            b.value = false;
            if (b.type != BlockType.analogInput) b.elapsed = 0.0;
          } else {
            b.value = false;
          }
        }
      }
    });
  }

  void _evaluateCycle(double dt) {
    if (isPowerOutage) return;
    final Map<String, PlcBlock> blockMap = {for (var b in blocks) b.id: b};

    bool getPinVal(String blockId, int pinIndex) {
      final w = wires.where(
        (wire) => wire.toBlockId == blockId && wire.toPinIndex == pinIndex,
      );
      if (w.isEmpty) return false;
      return blockMap[w.first.fromBlockId]?.value ?? false;
    }

    double getAnalogPinVal(String blockId, int pinIndex) {
      final w = wires.where(
        (wire) => wire.toBlockId == blockId && wire.toPinIndex == pinIndex,
      );
      if (w.isEmpty) return 0.0;
      return blockMap[w.first.fromBlockId]?.analogVal ?? 0.0;
    }

    List<bool> getConnectedInputs(PlcBlock b) {
      final list = <bool>[];
      for (int i = 0; i < b.type.inputCount; i++) {
        if (wires.any((w) => w.toBlockId == b.id && w.toPinIndex == i)) {
          list.add(getPinVal(b.id, i));
        }
      }
      return list;
    }

    setState(() {
      for (int pass = 0; pass < 2; pass++) {
        for (final b in blocks) {
          switch (b.type) {
            case BlockType.input:
              break;
            case BlockType.analogInput:
              b.value = b.analogVal > 0.0;
              break;
            case BlockType.high:
              b.value = true;
              break;
            case BlockType.low:
              b.value = false;
              break;
            case BlockType.weeklyTimer:
            case BlockType.yearlyTimer:
              if (b.param <= b.param2) {
                b.value = simHour >= b.param && simHour < b.param2;
              } else {
                b.value = simHour >= b.param || simHour < b.param2;
              }
              break;
            case BlockType.output:
            case BlockType.flag:
            case BlockType.messageText:
              b.value = getPinVal(b.id, 0);
              break;
            case BlockType.analogOutput:
              b.analogVal = getAnalogPinVal(b.id, 0);
              b.value = b.analogVal > 0.0;
              break;
            case BlockType.andGate:
              final ins = getConnectedInputs(b);
              b.value = ins.isNotEmpty && ins.every((v) => v);
              break;
            case BlockType.andEdge:
              if (pass == 0) {
                final ins = getConnectedInputs(b);
                final cur = ins.isNotEmpty && ins.every((v) => v);
                b.value = cur && !b.prevClk;
                b.prevClk = cur;
              }
              break;
            case BlockType.orGate:
              b.value = getConnectedInputs(b).any((v) => v);
              break;
            case BlockType.nandGate:
              final ins = getConnectedInputs(b);
              b.value = !(ins.isNotEmpty && ins.every((v) => v));
              break;
            case BlockType.norGate:
              b.value = !getConnectedInputs(b).any((v) => v);
              break;
            case BlockType.xorGate:
              b.value = getPinVal(b.id, 0) != getPinVal(b.id, 1);
              break;
            case BlockType.notGate:
              b.value = !getPinVal(b.id, 0);
              break;
            case BlockType.rs:
              final s = getPinVal(b.id, 0);
              final r = getPinVal(b.id, 1);
              if (r) {
                b.value = false;
              } else if (s) {
                b.value = true;
              }
              break;
            case BlockType.impulse:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                final rst = getPinVal(b.id, 1);
                if (rst) {
                  b.value = false;
                } else if (trg && !b.prevClk) {
                  b.value = !b.value;
                }
                b.prevClk = trg;
              }
              break;
            case BlockType.shiftRegister:
              if (pass == 0) {
                final dataIn = getPinVal(b.id, 0);
                final trg = getPinVal(b.id, 1);
                if (trg && !b.prevClk) b.value = dataIn;
                b.prevClk = trg;
              }
              break;
            case BlockType.ton:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                if (trg) {
                  if (b.elapsed < b.param) b.elapsed += dt;
                  b.value = b.elapsed >= b.param;
                } else {
                  b.elapsed = 0.0;
                  b.value = false;
                }
              }
              break;
            case BlockType.tonr:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                final rst = getPinVal(b.id, 1);
                if (rst) {
                  b.elapsed = 0.0;
                  b.value = false;
                } else if (trg) {
                  if (b.elapsed < b.param) b.elapsed += dt;
                  b.value = b.elapsed >= b.param;
                }
              }
              break;
            case BlockType.tof:
            case BlockType.stairway:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                if (trg) {
                  b.value = true;
                  b.elapsed = 0.0;
                } else if (b.value) {
                  b.elapsed += dt;
                  if (b.elapsed >= b.param) {
                    b.value = false;
                    b.elapsed = b.param;
                  }
                }
              }
              break;
            case BlockType.tp:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                if (trg && !b.prevClk) {
                  b.value = true;
                  b.elapsed = 0.0;
                }
                if (b.value) {
                  b.elapsed += dt;
                  if (b.elapsed >= b.param) {
                    b.value = false;
                    b.elapsed = 0.0;
                  }
                }
                b.prevClk = trg;
              }
              break;
            case BlockType.pulse:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                if (trg) {
                  b.elapsed += dt;
                  if (b.elapsed >= b.param) {
                    b.elapsed = 0.0;
                    b.value = !b.value;
                  }
                } else {
                  b.elapsed = 0.0;
                  b.value = false;
                }
              }
              break;
            case BlockType.ctud:
              if (pass == 0) {
                final cntUp = getPinVal(b.id, 0);
                final cntDn = getPinVal(b.id, 1);
                final rst = getPinVal(b.id, 2);
                if (rst) {
                  b.elapsed = 0.0;
                  b.value = false;
                } else {
                  if (cntUp && !b.prevClk) b.elapsed += 1.0;
                  if (cntDn && b.elapsed > 0) b.elapsed = math.max(0, b.elapsed - 0.5);
                }
                b.prevClk = cntUp;
                b.value = b.elapsed >= b.param;
              }
              break;
            case BlockType.hoursCounter:
              if (pass == 0) {
                final en = getPinVal(b.id, 0);
                final rst = getPinVal(b.id, 1);
                if (rst) {
                  b.elapsed = 0.0;
                  b.value = false;
                } else if (en) {
                  b.elapsed += dt;
                  b.value = b.elapsed >= b.param;
                }
              }
              break;
            case BlockType.analogCmp:
              b.analogVal = getAnalogPinVal(b.id, 0);
              if (b.analogVal >= b.param) {
                b.value = true;
              } else if (b.analogVal <= b.param2) {
                b.value = false;
              }
              break;
            case BlockType.analogAmp:
              b.analogVal = (getAnalogPinVal(b.id, 0) * b.param).clamp(0.0, 100.0);
              b.value = b.analogVal > 0;
              break;
            case BlockType.analogMath:
              b.analogVal = getAnalogPinVal(b.id, 0) + getAnalogPinVal(b.id, 1);
              b.value = b.analogVal >= b.param;
              break;
            case BlockType.piController:
              final pv = getAnalogPinVal(b.id, 0);
              final en = getPinVal(b.id, 1);
              if (en) {
                final err = b.param - pv;
                b.analogVal = (err * 1.5).clamp(0.0, 10.0);
                b.value = b.analogVal > 0.5;
              } else {
                b.analogVal = 0.0;
                b.value = false;
              }
              break;
          }
        }
      }

      // Update plant equipment simulation levels
      for (final b in blocks) {
        if (b.type == BlockType.output) {
          if (b.equipmentType == EquipmentType.pump) {
            final cur = tankLevels[b.id] ?? 0.3;
            tankLevels[b.id] = b.value
                ? math.min(1.0, cur + 0.03)
                : math.max(0.1, cur - 0.01);
          } else if (b.equipmentType == EquipmentType.gate) {
            final cur = gatePositions[b.id] ?? 0.0;
            gatePositions[b.id] = b.value
                ? math.min(1.0, cur + 0.05)
                : math.max(0.0, cur - 0.05);
          }
        }
      }

      final snap = <String, bool>{};
      for (final b in blocks) {
        if (b.type == BlockType.input || b.type == BlockType.output) {
          snap[b.label] = b.value;
        }
      }
      scopeHistory.add(snap);
      if (scopeHistory.length > 60) scopeHistory.removeAt(0);
    });
  }

  String _identifyDrawnCircuit() {
    if (blocks.isEmpty) return 'صفحه خالی است — هیچ مداری رسم نشده است.';

    final types = blocks.map((b) => b.type).toSet();
    final outCount = blocks.where((b) => b.type == BlockType.output).length;
    final rsCount = blocks.where((b) => b.type == BlockType.rs).length;
    final notCount = blocks.where((b) => b.type == BlockType.notGate).length;
    final stwCount = blocks.where((b) => b.type == BlockType.stairway).length;

    if (stwCount >= 3 && outCount >= 4) {
      return 'مدار شستی چندکاره روشنایی (شکل ۲۸ - کار عملی ۶ کتاب)';
    }
    if (types.contains(BlockType.rs) &&
        types.contains(BlockType.ton) &&
        types.contains(BlockType.notGate) &&
        types.contains(BlockType.andGate) &&
        outCount >= 3) {
      return 'مدار راه‌اندازی موتور سه‌فاز ستاره-مثلث خودکار (Star-Delta)';
    }
    if (rsCount >= 2 && notCount >= 2 && outCount >= 2) {
      return 'مدار موتور چپ‌گرد و راست‌گرد (با اینترلاک حفاظتی)';
    }
    if (rsCount >= 2 && notCount == 0 && outCount >= 2) {
      return 'مدار چپ‌گرد و راست‌گرد (هشدار: بدون اینترلاک!)';
    }
    if (types.contains(BlockType.xorGate) && outCount == 1) {
      return 'مدار روشنایی تبدیل (کلید تبدیل با گیت XOR)';
    }
    if (types.contains(BlockType.stairway) || types.contains(BlockType.tof)) {
      return 'مدار روشنایی راه‌پله (تایمر قطع‌کن راه‌پله)';
    }
    if (types.contains(BlockType.impulse)) {
      return 'مدار روشنایی با رله پله‌ای (Impulse Relay)';
    }
    if (types.contains(BlockType.weeklyTimer) || types.contains(BlockType.yearlyTimer)) {
      return 'مدار روشنایی هوشمند با تایمر هفتگی';
    }
    if (types.contains(BlockType.notGate) && types.contains(BlockType.rs) && outCount == 1) {
      return 'مدار کنترل اتوماتیک پمپ و مخزن آب (سنسور کف و سقف)';
    }
    if (types.contains(BlockType.rs) && outCount == 1) {
      return 'مدار استارت/استپ دائم موتور (Self-Hold با RS)';
    }
    if (types.contains(BlockType.analogInput) && types.contains(BlockType.analogCmp)) {
      return 'مدار کنترل دما / سطح آنالوگ با مقایسه‌گر';
    }
    if (types.contains(BlockType.ctud)) {
      return 'مدار شمارنده قطعات صنعتی (CTUD)';
    }
    if (types.contains(BlockType.tonr)) {
      return 'مدار تایمر ماندگار مقاوم در برابر قطع برق (TONR)';
    }
    if (types.contains(BlockType.pulse)) {
      return 'مدار چشمک‌زن / پالس‌ساز متناوب (Async Pulse)';
    }

    final gateNames = blocks
        .where((b) => b.type.category == BlockCategory.gf)
        .map((b) => b.type.title)
        .toSet()
        .join('، ');
    return 'مدار منطقی سفارشی (${blocks.length} بلوک${gateNames.isNotEmpty ? " شامل $gateNames" : ""})';
  }

  void _drawCircuitByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;

    if (q.contains('ستاره') || q.contains('مثلث') || q.contains('star')) {
      _loadTemplate('p2_stardelta');
    } else if (q.contains('چندکاره') || q.contains('28') || q.contains('۲۸') || q.contains('همکف')) {
      _loadTemplate('p1_multi_switch');
    } else if (q.contains('پمپ') || q.contains('مخزن') || q.contains('آب') || q.contains('pump')) {
      _loadTemplate('p3_pump');
    } else if (q.contains('چپ') || q.contains('راست') || q.contains('دوجهت') || q.contains('rev')) {
      _loadTemplate('fault_rev');
    } else if (q.contains('ماندگار') || q.contains('قطع برق') || q.contains('tonr')) {
      _loadTemplate('p5_retentive');
    } else if (q.contains('تبدیل') || q.contains('xor')) {
      _loadBasicCircuit(BlockType.xorGate, 2);
    } else if (q.contains('راه‌پله') || q.contains('راه پله') || q.contains('پله')) {
      _loadBasicCircuit(BlockType.stairway, 1);
    } else if (q.contains('پله‌ای') || q.contains('impulse')) {
      _loadBasicCircuit(BlockType.impulse, 2);
    } else if (q.contains('استارت') || q.contains('دائم') || q.contains('rs')) {
      _loadBasicCircuit(BlockType.rs, 2);
    } else if (q.contains('شمارنده') || q.contains('قطعه') || q.contains('count')) {
      _loadBasicCircuit(BlockType.ctud, 1);
    } else if (q.contains('چشمک') || q.contains('پالس') || q.contains('blink')) {
      _loadBasicCircuit(BlockType.pulse, 1);
    } else if (q.contains('دما') || q.contains('آنالوگ') || q.contains('analog')) {
      _loadBasicCircuit(BlockType.analogCmp, 1);
    } else if (q.contains('nand')) {
      _loadBasicCircuit(BlockType.nandGate, 2);
    } else if (q.contains('nor')) {
      _loadBasicCircuit(BlockType.norGate, 2);
    } else if (q.contains('and') || q.contains('سری')) {
      _loadBasicCircuit(BlockType.andGate, 2);
    } else if (q.contains('or') || q.contains('موازی')) {
      _loadBasicCircuit(BlockType.orGate, 2);
    } else if (q.contains('not') || q.contains('نقیض')) {
      _loadBasicCircuit(BlockType.notGate, 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نام مدار شناخته نشد! مثلاً بنویس: ستاره مثلث، تبدیل، راه‌پله، پمپ آب، شمارنده، چشمک‌زن، AND'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('مدار "$query" رسم شد!')),
    );
  }

  void _loadBasicCircuit(BlockType gateType, int inCount) {
    if (isSimulating) _toggleSimulation();
    setState(() {
      blocks.clear();
      wires.clear();
      selectedOutputBlockId = null;
      _idCounter = 1;

      if (gateType == BlockType.analogCmp) {
        blocks = [
          PlcBlock(id: 'b1', blockCode: 'AI1', type: BlockType.analogInput, label: 'سنسور دما', x: 40, y: 100, analogVal: 4.5),
          PlcBlock(id: 'b2', blockCode: 'B001', type: BlockType.analogCmp, label: 'A_CMP', x: 200, y: 100, param: 6.0, param2: 4.0),
          PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'فن', x: 360, y: 100, powerWatts: 300, equipmentType: EquipmentType.motor),
        ];
        wires = [
          PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b2', toPinIndex: 0),
          PlcWire(id: 'w2', fromBlockId: 'b2', toBlockId: 'q1', toPinIndex: 0),
        ];
        return;
      }

      for (int i = 0; i < inCount; i++) {
        blocks.add(PlcBlock(
          id: 'i${i + 1}',
          blockCode: 'I${i + 1}',
          type: BlockType.input,
          label: 'I${i + 1}',
          x: 40,
          y: 50.0 + i * 100.0,
        ));
      }
      blocks.add(PlcBlock(
        id: 'g1',
        blockCode: 'B001',
        type: gateType,
        label: gateType.shortName,
        x: 210,
        y: 90,
        param: gateType == BlockType.ctud ? 5.0 : 4.0,
      ));
      blocks.add(PlcBlock(
        id: 'q1',
        blockCode: 'Q1',
        type: BlockType.output,
        label: 'Q1',
        x: 380,
        y: 90,
      ));
      for (int i = 0; i < inCount; i++) {
        wires.add(PlcWire(
          id: 'w${i + 1}',
          fromBlockId: 'i${i + 1}',
          toBlockId: 'g1',
          toPinIndex: i,
        ));
      }
      wires.add(PlcWire(
        id: 'w_out',
        fromBlockId: 'g1',
        toBlockId: 'q1',
        toPinIndex: 0,
      ));
      _idCounter = 20;
    });
  }

  void _openCircuitAssistantDialog() {
    final nameCtrl = TextEditingController();
    final detectedName = _identifyDrawnCircuit();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دستیار هوشمند مدار (رسم و تشخیص)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '۱. تشخیص مداری که الان کشیده‌ای:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.teal),
                ),
                child: Text(
                  detectedName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Divider(height: 20),
              const Text(
                '۲. اسم مدار را بنویس تا خودش بکشد:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'مثلاً: ستاره مثلث، تبدیل، راه‌پله، پمپ آب، شمارنده...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final q = nameCtrl.text;
              Navigator.pop(ctx);
              _drawCircuitByName(q);
            },
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text('بکش!'),
          ),
        ],
      ),
    );
  }

  void _showPowerAndPanelBom() {
    final outputs = blocks.where((b) => b.type == BlockType.output).toList();
    const double plcBaseWatts = 3.5;
    double totalMaxWatts = plcBaseWatts;
    double activeNowWatts = plcBaseWatts;
    bool hasMotor = outputs.any(
      (q) => q.equipmentType == EquipmentType.motor || q.equipmentType == EquipmentType.pump,
    );

    for (final q in outputs) {
      totalMaxWatts += q.powerWatts;
      if (!isSimulating || q.value) {
        activeNowWatts += q.powerWatts;
      }
    }

    final double maxCurrent = totalMaxWatts / 220.0;
    final double activeCurrent = activeNowWatts / 220.0;

    // Auto-select MCB, Contactor, Bimetal, Wire Cross-Section
    String mcbRating = '6 A';
    String contactor = '9 A (LC1D09)';
    String bimetal = '1 - 1.6 A';
    String wireSize = '1.5 mm²';

    if (maxCurrent > 25) {
      mcbRating = '32 A';
      contactor = '32 A (LC1D32)';
      bimetal = '23 - 32 A';
      wireSize = '6 mm²';
    } else if (maxCurrent > 16) {
      mcbRating = '25 A';
      contactor = '25 A (LC1D25)';
      bimetal = '17 - 25 A';
      wireSize = '4 mm²';
    } else if (maxCurrent > 10) {
      mcbRating = '16 A';
      contactor = '18 A (LC1D18)';
      bimetal = '12 - 18 A';
      wireSize = '2.5 mm²';
    } else if (maxCurrent > 6) {
      mcbRating = '10 A';
      contactor = '12 A (LC1D12)';
      bimetal = '7 - 10 A';
      wireSize = '1.5 mm²';
    } else if (maxCurrent > 2) {
      mcbRating = '6 A';
      contactor = '9 A (LC1D09)';
      bimetal = '2.5 - 4 A';
      wireSize = '1.5 mm²';
    }

    final mcbCurve = hasMotor ? 'تیپ C (موتوری)' : 'تیپ B (روشنایی)';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مصرف برق و تجهیزات تابلو برق'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('توان فعلی: ${activeNowWatts.toStringAsFixed(0)} W | حداکثر: ${totalMaxWatts.toStringAsFixed(0)} W',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              Text('جریان فعلی: ${activeCurrent.toStringAsFixed(2)} A | جریان نامی کل: ${maxCurrent.toStringAsFixed(2)} A'),
              const Divider(),
              const Text('تجهیزات پیشنهادی تابلو برق:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              const SizedBox(height: 4),
              Text('• کلید مینیاتوری (MCB): $mcbRating — $mcbCurve'),
              Text('• کنتاکتور پیشنهادی: $contactor'),
              if (hasMotor) Text('• رله حرارتی (بیمتال): $bimetal'),
              Text('• سطح مقطع سیم قدرت: $wireSize'),
              const Divider(),
              const Text('مصرف هر خروجی:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...outputs.map((q) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${q.blockCode} (${q.label})'),
                      Text('${q.powerWatts.toInt()} W'),
                    ],
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSnapshotAndReport() async {
    Uint8List? pngBytes;
    try {
      final boundary = _canvasRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData?.buffer.asUint8List();
      }
    } catch (_) {}

    final sb = StringBuffer();
    sb.writeln('=== گزارش نقشه PLC - نرم‌افزار MOHSEN ===');
    sb.writeln('تعداد بلوک‌ها: ${blocks.length} | تعداد اتصالات: ${wires.length}');
    for (final b in blocks) {
      sb.writeln('- ${b.blockCode} [${b.type.shortName}] : ${b.label}');
    }
    sb.writeln('--- اتصالات ---');
    for (final w in wires) {
      final f = blocks.firstWhere((e) => e.id == w.fromBlockId, orElse: () => blocks.first);
      final t = blocks.firstWhere((e) => e.id == w.toBlockId, orElse: () => blocks.first);
      sb.writeln('${f.blockCode} --> ${t.blockCode} (Pin ${w.toPinIndex + 1})');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خروجی تصویر نقشه و گزارش کارگاهی'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pngBytes != null)
                  Container(
                    height: 180,
                    decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
                    child: Image.memory(pngBytes, fit: BoxFit.contain),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade100,
                  child: SelectableText(
                    sb.toString(),
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sb.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('گزارش متنی کپی شد!')),
              );
            },
            child: const Text('کپی گزارش'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  void _checkCircuitDiagnostics() {
    final issues = <String>[];
    for (final q in blocks.where((b) => b.type == BlockType.output)) {
      if (!wires.any((w) => w.toBlockId == q.id)) {
        issues.add('• خروجی ${q.blockCode} (${q.label}) به هیچ مداری وصل نیست!');
      }
    }
    final rsCount = blocks.where((b) => b.type == BlockType.rs).length;
    final notCount = blocks.where((b) => b.type == BlockType.notGate).length;
    if (rsCount >= 2 && notCount == 0) {
      issues.add('• هشدار عیب‌یابی: دو رله RS دارید ولی گیت NOT برای اینترلاک حفاظتی دیده نشد (خطر هم‌زمانی چپ‌گرد/راست‌گرد).');
    }
    if (blocks.isEmpty) {
      issues.add('• صفحه نقشه خالی است.');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نتیجه عیب‌یابی خودکار مدار'),
        content: Text(
          issues.isEmpty
              ? 'مدار سالم است و هیچ خطای سیم‌کشی یا اتصال بازی پیدا نشد.'
              : issues.join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  void _showTruthTable() {
    final inputs = blocks.where((b) => b.type == BlockType.input).toList();
    final outputs = blocks.where((b) => b.type == BlockType.output).toList();

    if (inputs.isEmpty || outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداقل یک ورودی (I) و یک خروجی (Q) لازم است.')),
      );
      return;
    }

    final evalInputs = inputs.take(5).toList();
    final int rowsCount = 1 << evalInputs.length;

    bool evalBlock(String id, Map<String, bool> inpState, int depth) {
      if (depth > 15) return false;
      final b = blocks.firstWhere((e) => e.id == id);
      if (b.type == BlockType.input) return inpState[b.id] ?? false;
      if (b.type == BlockType.high) return true;
      if (b.type == BlockType.low) return false;

      bool getIn(int pin) {
        final w = wires.where((e) => e.toBlockId == b.id && e.toPinIndex == pin);
        if (w.isEmpty) return false;
        return evalBlock(w.first.fromBlockId, inpState, depth + 1);
      }

      List<bool> connIns() {
        final res = <bool>[];
        for (int i = 0; i < b.type.inputCount; i++) {
          if (wires.any((e) => e.toBlockId == b.id && e.toPinIndex == i)) {
            res.add(getIn(i));
          }
        }
        return res;
      }

      switch (b.type) {
        case BlockType.output:
        case BlockType.flag:
        case BlockType.ton:
        case BlockType.tof:
        case BlockType.tp:
        case BlockType.stairway:
          return getIn(0);
        case BlockType.notGate:
          return !getIn(0);
        case BlockType.andGate:
        case BlockType.andEdge:
          final ins = connIns();
          return ins.isNotEmpty && ins.every((v) => v);
        case BlockType.orGate:
          return connIns().any((v) => v);
        case BlockType.nandGate:
          final ins = connIns();
          return !(ins.isNotEmpty && ins.every((v) => v));
        case BlockType.norGate:
          return !connIns().any((v) => v);
        case BlockType.xorGate:
          return getIn(0) != getIn(1);
        case BlockType.rs:
          final s = getIn(0);
          final r = getIn(1);
          if (r) return false;
          return s;
        default:
          return getIn(0);
      }
    }

    final List<List<bool>> tableRows = [];
    for (int r = 0; r < rowsCount; r++) {
      final inpState = <String, bool>{};
      final row = <bool>[];
      for (int c = 0; c < evalInputs.length; c++) {
        final bit = ((r >> (evalInputs.length - 1 - c)) & 1) == 1;
        inpState[evalInputs[c].id] = bit;
        row.add(bit);
      }
      for (final out in outputs) {
        row.add(evalBlock(out.id, inpState, 0));
      }
      tableRows.add(row);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('جدول ارزشی مدار (Truth Table)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFF00695C)),
                columnSpacing: 16,
                columns: [
                  ...evalInputs.map((i) => DataColumn(
                        label: Text(i.label,
                            style: const TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold)),
                      )),
                  ...outputs.map((o) => DataColumn(
                        label: Text(o.label,
                            style: const TextStyle(
                                color: Colors.lightGreenAccent,
                                fontWeight: FontWeight.bold)),
                      )),
                ],
                rows: tableRows.map((row) {
                  return DataRow(
                    cells: row.asMap().entries.map((entry) {
                      final isOut = entry.key >= evalInputs.length;
                      final val = entry.value;
                      return DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: val
                                ? (isOut
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.15))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            val ? '1' : '0',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: val
                                  ? (isOut
                                      ? Colors.green.shade800
                                      : Colors.blue.shade800)
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  List<LadRung> _convertFbdToLadder() {
    final Map<String, PlcBlock> blockMap = {for (var b in blocks) b.id: b};

    LadNode? buildNode(String blockId, {bool invert = false, int depth = 0}) {
      if (depth > 10) return null;
      final b = blockMap[blockId];
      if (b == null) return null;

      List<String> incomingIds() {
        final res = <String>[];
        for (int i = 0; i < b.type.inputCount; i++) {
          final w = wires.where(
            (wire) => wire.toBlockId == b.id && wire.toPinIndex == i,
          );
          if (w.isNotEmpty) res.add(w.first.fromBlockId);
        }
        return res;
      }

      switch (b.type) {
        case BlockType.notGate:
          final ins = incomingIds();
          if (ins.isEmpty) return LadContact(b.id, b.label, inverted: !invert);
          return buildNode(ins.first, invert: !invert, depth: depth + 1);
        case BlockType.andGate:
        case BlockType.andEdge:
          final ins = incomingIds();
          if (ins.isEmpty) return null;
          if (invert) {
            return LadParallel(ins
                .map((id) => buildNode(id, invert: true, depth: depth + 1))
                .whereType<LadNode>()
                .toList());
          }
          return LadSeries(ins
              .map((id) => buildNode(id, invert: false, depth: depth + 1))
              .whereType<LadNode>()
              .toList());
        case BlockType.nandGate:
          final ins = incomingIds();
          if (ins.isEmpty) return null;
          if (!invert) {
            return LadParallel(ins
                .map((id) => buildNode(id, invert: true, depth: depth + 1))
                .whereType<LadNode>()
                .toList());
          }
          return LadSeries(ins
              .map((id) => buildNode(id, invert: false, depth: depth + 1))
              .whereType<LadNode>()
              .toList());
        case BlockType.orGate:
          final ins = incomingIds();
          if (ins.isEmpty) return null;
          if (invert) {
            return LadSeries(ins
                .map((id) => buildNode(id, invert: true, depth: depth + 1))
                .whereType<LadNode>()
                .toList());
          }
          return LadParallel(ins
              .map((id) => buildNode(id, invert: false, depth: depth + 1))
              .whereType<LadNode>()
              .toList());
        case BlockType.norGate:
          final ins = incomingIds();
          if (ins.isEmpty) return null;
          if (!invert) {
            return LadSeries(ins
                .map((id) => buildNode(id, invert: true, depth: depth + 1))
                .whereType<LadNode>()
                .toList());
          }
          return LadParallel(ins
              .map((id) => buildNode(id, invert: false, depth: depth + 1))
              .whereType<LadNode>()
              .toList());
        case BlockType.xorGate:
          final ins = incomingIds();
          if (ins.length < 2) return LadContact(b.id, b.label, inverted: invert);
          final a1 = buildNode(ins[0], invert: false, depth: depth + 1);
          final b1 = buildNode(ins[1], invert: true, depth: depth + 1);
          final a2 = buildNode(ins[0], invert: true, depth: depth + 1);
          final b2 = buildNode(ins[1], invert: false, depth: depth + 1);
          if (a1 != null && b1 != null && a2 != null && b2 != null) {
            return LadParallel([
              LadSeries([a1, b1]),
              LadSeries([a2, b2]),
            ]);
          }
          return LadContact(b.id, b.label, inverted: invert);
        default:
          return LadContact(b.id, b.label, inverted: invert);
      }
    }

    final rungs = <LadRung>[];
    for (final b in blocks) {
      if (b.type == BlockType.output ||
          b.type == BlockType.flag ||
          b.type == BlockType.messageText ||
          b.type.category == BlockCategory.sfTimer ||
          b.type.category == BlockCategory.sfCounter ||
          b.type == BlockType.rs ||
          b.type == BlockType.impulse) {
        if (b.type == BlockType.weeklyTimer || b.type == BlockType.yearlyTimer) {
          continue;
        }
        final w0 = wires.where((w) => w.toBlockId == b.id && w.toPinIndex == 0);
        LadNode? cond = w0.isNotEmpty ? buildNode(w0.first.fromBlockId) : null;
        rungs.add(LadRung(coilLabel: b.label, targetBlock: b, condition: cond));
      }
    }
    return rungs;
  }

  void _addBlock(BlockType type) {
    if (isSimulating) return;
    setState(() {
      int count = blocks.where((b) => b.type == type).length + 1;
      String code = 'B${(blocks.length + 1).toString().padLeft(3, '0')}';
      String label = '${type.shortName}$count';
      if (type == BlockType.input) {
        code = 'I$count';
        label = 'I$count';
      } else if (type == BlockType.output) {
        code = 'Q$count';
        label = 'Q$count';
      } else if (type == BlockType.flag) {
        code = 'M$count';
        label = 'M$count';
      } else if (type == BlockType.analogInput) {
        code = 'AI$count';
        label = 'AI$count';
      }

      blocks.add(
        PlcBlock(
          id: _nextId('b'),
          blockCode: code,
          type: type,
          label: label,
          x: 80.0 + (blocks.length % 5) * 30.0,
          y: 60.0 + (blocks.length % 4) * 30.0,
          param: type == BlockType.ctud
              ? 5.0
              : (type == BlockType.analogCmp
                  ? 6.0
                  : (type == BlockType.weeklyTimer ? 18.0 : 3.0)),
          param2: type == BlockType.analogCmp
              ? 4.0
              : (type == BlockType.weeklyTimer ? 6.0 : 2.0),
          analogVal: type == BlockType.analogInput ? 5.0 : 0.0,
        ),
      );
    });
  }

  void _handlePinTap(String blockId, bool isOutput, int pinIndex) {
    if (isSimulating) return;
    setState(() {
      if (isOutput) {
        selectedOutputBlockId =
            (selectedOutputBlockId == blockId) ? null : blockId;
      } else if (selectedOutputBlockId != null &&
          selectedOutputBlockId != blockId) {
        wires.removeWhere(
          (w) => w.toBlockId == blockId && w.toPinIndex == pinIndex,
        );
        wires.add(
          PlcWire(
            id: _nextId('w'),
            fromBlockId: selectedOutputBlockId!,
            toBlockId: blockId,
            toPinIndex: pinIndex,
          ),
        );
        selectedOutputBlockId = null;
      } else {
        wires.removeWhere(
          (w) => w.toBlockId == blockId && w.toPinIndex == pinIndex,
        );
      }
    });
  }

  void _openBlockSettings(PlcBlock block) {
    if (isSimulating) return;
    final labelCtrl = TextEditingController(text: block.label);
    final paramCtrl = TextEditingController(text: block.param.toStringAsFixed(1));
    final param2Ctrl = TextEditingController(text: block.param2.toStringAsFixed(1));
    final msgCtrl = TextEditingController(text: block.messageText);
    final wattCtrl = TextEditingController(text: block.powerWatts.toStringAsFixed(0));
    bool isToggle = block.isToggle;
    EquipmentType eqType = block.equipmentType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Properties: ${block.blockCode}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'نام / برچسب',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: paramCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'پارامتر اول (زمان / PV / آستانه)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (block.type == BlockType.output) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: wattCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'توان مصرفی خروجی (وات)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<EquipmentType>(
                    value: eqType,
                    decoration: const InputDecoration(
                      labelText: 'نوع تجهیز در نمای کارگاهی',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: EquipmentType.lamp, child: Text('لامپ / روشنایی')),
                      DropdownMenuItem(value: EquipmentType.motor, child: Text('موتور سه‌فاز')),
                      DropdownMenuItem(value: EquipmentType.pump, child: Text('پمپ و مخزن آب')),
                      DropdownMenuItem(value: EquipmentType.gate, child: Text('درب پارکینگ / جک')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDlgState(() => eqType = v);
                    },
                  ),
                ],
                if (block.type == BlockType.messageText) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: msgCtrl,
                    decoration: const InputDecoration(
                      labelText: 'متن نمایشگر LCD',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (block.type == BlockType.input) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('کلید دائم (Switch)'),
                    value: isToggle,
                    onChanged: (v) => setDlgState(() => isToggle = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  wires.removeWhere(
                    (w) => w.fromBlockId == block.id || w.toBlockId == block.id,
                  );
                  blocks.removeWhere((b) => b.id == block.id);
                });
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (labelCtrl.text.trim().isNotEmpty) {
                    block.label = labelCtrl.text.trim();
                  }
                  final parsed = double.tryParse(paramCtrl.text.trim());
                  if (parsed != null && parsed >= 0) block.param = parsed;
                  final parsed2 = double.tryParse(param2Ctrl.text.trim());
                  if (parsed2 != null && parsed2 >= 0) block.param2 = parsed2;
                  final w = double.tryParse(wattCtrl.text.trim());
                  if (w != null && w >= 0) block.powerWatts = w;
                  if (msgCtrl.text.trim().isNotEmpty) {
                    block.messageText = msgCtrl.text.trim();
                  }
                  block.isToggle = isToggle;
                  block.equipmentType = eqType;
                });
                Navigator.pop(ctx);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _loadTemplate(String name) {
    if (isSimulating) _toggleSimulation();
    setState(() {
      blocks.clear();
      wires.clear();
      selectedOutputBlockId = null;
      _idCounter = 1;

      switch (name) {
        case 'p1_multi_switch':
          blocks = [
            PlcBlock(id: 'b1', blockCode: 'I1', type: BlockType.input, label: 'شستی موازی', x: 30, y: 30, isToggle: false),
            PlcBlock(id: 'b8', blockCode: 'B008', type: BlockType.ton, label: 'سه شستی', x: 160, y: 80, param: 5.0),
            PlcBlock(id: 'b4', blockCode: 'B004', type: BlockType.stairway, label: 'همکف', x: 380, y: 30, param: 15.0),
            PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'راهرو همکف', x: 520, y: 30, powerWatts: 200, equipmentType: EquipmentType.lamp),

            PlcBlock(id: 'b2', blockCode: 'I2', type: BlockType.input, label: 'راه‌پله', x: 30, y: 185, isToggle: false),
            PlcBlock(id: 'b01', blockCode: 'B001', type: BlockType.orGate, label: 'OR', x: 270, y: 180),
            PlcBlock(id: 'b9', blockCode: 'B009', type: BlockType.stairway, label: 'تایمر پله', x: 400, y: 180, param: 15.0),
            PlcBlock(id: 'q2', blockCode: 'Q2', type: BlockType.output, label: 'لامپ راه‌پله', x: 540, y: 180, powerWatts: 250, equipmentType: EquipmentType.lamp),

            PlcBlock(id: 'b3', blockCode: 'I3', type: BlockType.input, label: 'پاگرد', x: 30, y: 320, isToggle: false),
            PlcBlock(id: 'b02', blockCode: 'B002', type: BlockType.orGate, label: 'OR', x: 270, y: 315),
            PlcBlock(id: 'b6', blockCode: 'B006', type: BlockType.stairway, label: 'تایمر پاگرد', x: 400, y: 315, param: 15.0),
            PlcBlock(id: 'q3', blockCode: 'Q3', type: BlockType.output, label: 'لامپ پاگرد', x: 540, y: 315, powerWatts: 250, equipmentType: EquipmentType.lamp),

            PlcBlock(id: 'b4i', blockCode: 'I4', type: BlockType.input, label: 'طبقه ۱', x: 30, y: 455, isToggle: false),
            PlcBlock(id: 'b03', blockCode: 'B003', type: BlockType.orGate, label: 'OR', x: 270, y: 450),
            PlcBlock(id: 'b5', blockCode: 'B005', type: BlockType.stairway, label: 'طبقه اول', x: 400, y: 450, param: 15.0),
            PlcBlock(id: 'q4', blockCode: 'Q4', type: BlockType.output, label: 'راهرو طبقه ۱', x: 540, y: 450, powerWatts: 200, equipmentType: EquipmentType.lamp),
          ];
          wires = [
            PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b4', toPinIndex: 0),
            PlcWire(id: 'w2', fromBlockId: 'b4', toBlockId: 'q1', toPinIndex: 0),
            PlcWire(id: 'w3', fromBlockId: 'b1', toBlockId: 'b8', toPinIndex: 0),
            PlcWire(id: 'w4', fromBlockId: 'b8', toBlockId: 'b01', toPinIndex: 0),
            PlcWire(id: 'w5', fromBlockId: 'b2', toBlockId: 'b01', toPinIndex: 1),
            PlcWire(id: 'w6', fromBlockId: 'b01', toBlockId: 'b9', toPinIndex: 0),
            PlcWire(id: 'w7', fromBlockId: 'b9', toBlockId: 'q2', toPinIndex: 0),
            PlcWire(id: 'w8', fromBlockId: 'b8', toBlockId: 'b02', toPinIndex: 0),
            PlcWire(id: 'w9', fromBlockId: 'b3', toBlockId: 'b02', toPinIndex: 1),
            PlcWire(id: 'w10', fromBlockId: 'b02', toBlockId: 'b6', toPinIndex: 0),
            PlcWire(id: 'w11', fromBlockId: 'b6', toBlockId: 'q3', toPinIndex: 0),
            PlcWire(id: 'w12', fromBlockId: 'b8', toBlockId: 'b03', toPinIndex: 0),
            PlcWire(id: 'w13', fromBlockId: 'b4i', toBlockId: 'b03', toPinIndex: 1),
            PlcWire(id: 'w14', fromBlockId: 'b03', toBlockId: 'b5', toPinIndex: 0),
            PlcWire(id: 'w15', fromBlockId: 'b5', toBlockId: 'q4', toPinIndex: 0),
          ];
          break;
        case 'p2_stardelta':
          blocks = [
            PlcBlock(id: 'b1', blockCode: 'I1', type: BlockType.input, label: 'Start', x: 40, y: 40, isToggle: false),
            PlcBlock(id: 'b2', blockCode: 'I2', type: BlockType.input, label: 'Stop', x: 40, y: 140, isToggle: false),
            PlcBlock(id: 'b3', blockCode: 'B001', type: BlockType.rs, label: 'RS', x: 160, y: 80),
            PlcBlock(id: 'b4', blockCode: 'B002', type: BlockType.ton, label: 'T1', x: 160, y: 185, param: 4.0),
            PlcBlock(id: 'b5', blockCode: 'B003', type: BlockType.notGate, label: 'NOT', x: 280, y: 145),
            PlcBlock(id: 'b6', blockCode: 'B004', type: BlockType.andGate, label: 'AND', x: 400, y: 125),
            PlcBlock(id: 'b7', blockCode: 'Q1', type: BlockType.output, label: 'Main', x: 400, y: 20, powerWatts: 2200, equipmentType: EquipmentType.motor),
            PlcBlock(id: 'b8', blockCode: 'Q2', type: BlockType.output, label: 'Star', x: 520, y: 125, powerWatts: 1100, equipmentType: EquipmentType.motor),
            PlcBlock(id: 'b9', blockCode: 'Q3', type: BlockType.output, label: 'Delta', x: 520, y: 220, powerWatts: 2200, equipmentType: EquipmentType.motor),
          ];
          wires = [
            PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b3', toPinIndex: 0),
            PlcWire(id: 'w2', fromBlockId: 'b2', toBlockId: 'b3', toPinIndex: 1),
            PlcWire(id: 'w3', fromBlockId: 'b3', toBlockId: 'b7', toPinIndex: 0),
            PlcWire(id: 'w4', fromBlockId: 'b3', toBlockId: 'b4', toPinIndex: 0),
            PlcWire(id: 'w5', fromBlockId: 'b4', toBlockId: 'b5', toPinIndex: 0),
            PlcWire(id: 'w6', fromBlockId: 'b3', toBlockId: 'b6', toPinIndex: 0),
            PlcWire(id: 'w7', fromBlockId: 'b5', toBlockId: 'b6', toPinIndex: 1),
            PlcWire(id: 'w8', fromBlockId: 'b6', toBlockId: 'b8', toPinIndex: 0),
            PlcWire(id: 'w9', fromBlockId: 'b4', toBlockId: 'b9', toPinIndex: 0),
          ];
          break;
        case 'p3_pump':
          blocks = [
            PlcBlock(id: 'b1', blockCode: 'I1', type: BlockType.input, label: 'کف', x: 40, y: 50),
            PlcBlock(id: 'b2', blockCode: 'I2', type: BlockType.input, label: 'سقف', x: 40, y: 160),
            PlcBlock(id: 'b3', blockCode: 'B001', type: BlockType.notGate, label: 'NOT', x: 170, y: 50),
            PlcBlock(id: 'b4', blockCode: 'B002', type: BlockType.rs, label: 'RS', x: 300, y: 100),
            PlcBlock(id: 'b5', blockCode: 'Q1', type: BlockType.output, label: 'پمپ آب', x: 440, y: 100, powerWatts: 1500, equipmentType: EquipmentType.pump),
          ];
          wires = [
            PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b3', toPinIndex: 0),
            PlcWire(id: 'w2', fromBlockId: 'b3', toBlockId: 'b4', toPinIndex: 0),
            PlcWire(id: 'w3', fromBlockId: 'b2', toBlockId: 'b4', toPinIndex: 1),
            PlcWire(id: 'w4', fromBlockId: 'b4', toBlockId: 'b5', toPinIndex: 0),
          ];
          break;
        case 'fault_rev':
          // Intentional Fault Circuit: Missing Interlock!
          blocks = [
            PlcBlock(id: 'b1', blockCode: 'I1', type: BlockType.input, label: 'راست', x: 40, y: 40, isToggle: false),
            PlcBlock(id: 'b2', blockCode: 'I2', type: BlockType.input, label: 'چپ', x: 40, y: 160, isToggle: false),
            PlcBlock(id: 'b3', blockCode: 'I3', type: BlockType.input, label: 'Stop', x: 40, y: 270, isToggle: false),
            PlcBlock(id: 'b4', blockCode: 'B001', type: BlockType.rs, label: 'RS_R', x: 220, y: 50),
            PlcBlock(id: 'b5', blockCode: 'B002', type: BlockType.rs, label: 'RS_L', x: 220, y: 170),
            PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'راست‌گرد', x: 400, y: 50, powerWatts: 1500, equipmentType: EquipmentType.motor),
            PlcBlock(id: 'q2', blockCode: 'Q2', type: BlockType.output, label: 'چپ‌گرد', x: 400, y: 170, powerWatts: 1500, equipmentType: EquipmentType.motor),
          ];
          wires = [
            PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b4', toPinIndex: 0),
            PlcWire(id: 'w2', fromBlockId: 'b3', toBlockId: 'b4', toPinIndex: 1),
            PlcWire(id: 'w3', fromBlockId: 'b4', toBlockId: 'q1', toPinIndex: 0),
            PlcWire(id: 'w4', fromBlockId: 'b2', toBlockId: 'b5', toPinIndex: 0),
            PlcWire(id: 'w5', fromBlockId: 'b3', toBlockId: 'b5', toPinIndex: 1),
            PlcWire(id: 'w6', fromBlockId: 'b5', toBlockId: 'q2', toPinIndex: 0),
          ];
          break;
        case 'p5_retentive':
          blocks = [
            PlcBlock(id: 'b1', blockCode: 'I1', type: BlockType.input, label: 'شروع', x: 40, y: 50),
            PlcBlock(id: 'b2', blockCode: 'I2', type: BlockType.input, label: 'ریست', x: 40, y: 160, isToggle: false),
            PlcBlock(id: 'b3', blockCode: 'B001', type: BlockType.tonr, label: 'TONR', x: 200, y: 100, param: 8.0),
            PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'آلارم', x: 360, y: 100, powerWatts: 100, equipmentType: EquipmentType.lamp),
          ];
          wires = [
            PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b3', toPinIndex: 0),
            PlcWire(id: 'w2', fromBlockId: 'b2', toBlockId: 'b3', toPinIndex: 1),
            PlcWire(id: 'w3', fromBlockId: 'b3', toBlockId: 'q1', toPinIndex: 0),
          ];
          break;
      }
      _idCounter = blocks.length + wires.length + 10;
    });
  }

  void _showJsonDialog() {
    final jsonStr = jsonEncode({
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'wires': wires.map((w) => w.toJson()).toList(),
    });
    final ctrl = TextEditingController(text: jsonStr);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save / Load Project (JSON)'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ctrl.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied!')),
              );
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final data = jsonDecode(ctrl.text);
                if (isSimulating) _toggleSimulation();
                setState(() {
                  blocks = (data['blocks'] as List)
                      .map((e) => PlcBlock.fromJson(e))
                      .toList();
                  wires = (data['wires'] as List)
                      .map((e) => PlcWire.fromJson(e))
                      .toList();
                });
                Navigator.pop(ctx);
              } catch (_) {}
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputs = blocks.where((b) => b.type == BlockType.input).toList();
    final analogInputs =
        blocks.where((b) => b.type == BlockType.analogInput).toList();
    final hasWeekly = blocks.any(
      (b) => b.type == BlockType.weeklyTimer || b.type == BlockType.yearlyTimer,
    );
    final outputs = blocks.where((b) => b.type == BlockType.output).toList();
    final activeMsg = isSimulating
        ? blocks.where((b) => b.type == BlockType.messageText && b.value).toList()
        : <PlcBlock>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Classic Desktop LOGO! Soft Comfort Menu & Toolbar ---
            Container(
              height: 38,
              color: const Color(0xFFE0E4E8),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'MOHSEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28),
                      icon: Icon(
                        showTreeSidebar ? Icons.menu_open : Icons.menu,
                        size: 18,
                        color: Colors.black87,
                      ),
                      onPressed: () =>
                          setState(() => showTreeSidebar = !showTreeSidebar),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'مدارها و تمرین‌ها',
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('مدارها ▾',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ),
                      onSelected: (val) {
                        if (val == 'clear') {
                          if (isSimulating) _toggleSimulation();
                          setState(() {
                            blocks.clear();
                            wires.clear();
                          });
                        } else if (val == 'json') {
                          _showJsonDialog();
                        } else if (val == 'diag') {
                          _checkCircuitDiagnostics();
                        } else {
                          _loadTemplate(val);
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'p1_multi_switch', child: Text('شکل ۲۸: مدار شستی چندکاره (کتاب)')),
                        PopupMenuItem(value: 'p2_stardelta', child: Text('پودمان ۲: ستاره-مثلث خودکار')),
                        PopupMenuItem(value: 'p3_pump', child: Text('پودمان ۳: پمپ و مخزن آب')),
                        PopupMenuItem(value: 'p5_retentive', child: Text('پودمان ۵: تایمر ماندگار (تست قطع برق)')),
                        PopupMenuDivider(),
                        PopupMenuItem(value: 'fault_rev', child: Text('تمرین عیب‌یابی: چپ‌گرد/راست‌گرد معیوب!')),
                        PopupMenuItem(value: 'diag', child: Text('بررسی خودکار خطای مدار')),
                        PopupMenuDivider(),
                        PopupMenuItem(value: 'json', child: Text('ذخیره / ورود JSON')),
                        PopupMenuItem(value: 'clear', child: Text('پاک کردن صفحه (مدار خالی)')),
                      ],
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: viewMode == 0
                          ? 'FBD'
                          : (viewMode == 1
                              ? 'LAD'
                              : (viewMode == 2 ? 'SCOPE' : 'کارگاه')),
                      icon: Icons.layers,
                      color: Colors.indigo,
                      onTap: () => setState(() => viewMode = (viewMode + 1) % 4),
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: isWireTool ? 'سیم‌کشی: فعال' : 'سیم‌کشی دستی',
                      icon: Icons.cable,
                      color: isWireTool ? Colors.deepOrange : Colors.blueGrey.shade700,
                      onTap: () => setState(() {
                        isWireTool = !isWireTool;
                        selectedOutputBlockId = null;
                      }),
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'دستیار مدار',
                      icon: Icons.auto_awesome,
                      color: Colors.purple.shade700,
                      onTap: _openCircuitAssistantDialog,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'مصرف/تابلو',
                      icon: Icons.bolt,
                      color: Colors.amber.shade800,
                      onTap: _showPowerAndPanelBom,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'جدول ارزشی',
                      icon: Icons.table_chart,
                      color: Colors.teal.shade800,
                      onTap: _showTruthTable,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'خروجی/چاپ',
                      icon: Icons.camera_alt,
                      color: Colors.brown.shade700,
                      onTap: _exportSnapshotAndReport,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: isSimulating ? 'STOP' : 'SIM (F3)',
                      icon: isSimulating ? Icons.stop : Icons.play_arrow,
                      color: isSimulating ? Colors.red : Colors.green.shade700,
                      onTap: _toggleSimulation,
                    ),
                  ],
                ),
              ),
            ),
            if (isPowerOutage && isSimulating)
              Container(
                width: double.infinity,
                color: Colors.red.shade900,
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: const Text(
                  '⚡ وضعیت قطع برق (Power Failure) — تایمرهای ماندگار (TONR) و شمارنده‌ها مقدار خود را حفظ می‌کنند',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            if (activeMsg.isNotEmpty)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFB300),
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  'LOGO! LCD: ${activeMsg.first.messageText}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'monospace'),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  if (showTreeSidebar && !isSimulating && viewMode == 0)
                    Container(
                      width: 150,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(right: BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(4),
                        children: [
                          _treeGroup('▼ Co (I/Q/M)', BlockCategory.co),
                          _treeGroup('▼ GF (Logic)', BlockCategory.gf),
                          _treeGroup('▼ SF (Timers)', BlockCategory.sfTimer),
                          _treeGroup('▼ SF (Counters)', BlockCategory.sfCounter),
                          _treeGroup('▼ SF (Analog)', BlockCategory.sfAnalog),
                          _treeGroup('▼ SF (Misc)', BlockCategory.sfMisc),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: viewMode == 0
                          ? _buildFbdCanvas()
                          : (viewMode == 1
                              ? _buildLadderView()
                              : (viewMode == 2
                                  ? _buildScopeView()
                                  : _buildPlantWorkshopView(outputs))),
                    ),
                  ),
                ],
              ),
            ),
            if (isSimulating)
              _buildSimIoBar(inputs, analogInputs, hasWeekly, outputs),
          ],
        ),
      ),
    );
  }

  Widget _topToolBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 3),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _treeGroup(String title, BlockCategory cat) {
    final items = BlockType.values.where((b) => b.category == cat).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00695C)),
          ),
        ),
        ...items.map((t) {
          return InkWell(
            onTap: () => _addBlock(t),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: t.logoBodyColor.withOpacity(0.55),
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '${t.shortName}  ${t.title}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildFbdCanvas() {
    return RepaintBoundary(
      key: _canvasRepaintKey,
      child: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(400),
        minScale: 0.4,
        maxScale: 2.0,
        child: SizedBox(
          width: 1400,
          height: 1000,
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(1400, 1000),
                painter: _CheckeredGridAndWirePainter(
                  blocks: blocks,
                  wires: wires,
                  blockWidth: blockWidth,
                  blockHeight: blockHeight,
                  isSimulating: isSimulating,
                  dragStart: dragWireStart,
                  dragEnd: dragWireCurrent,
                ),
              ),
              ...blocks.map((b) => _buildBlockWidget(b)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantWorkshopView(List<PlcBlock> outputs) {
    if (outputs.isEmpty) {
      return const Center(
        child: Text('هیچ خروجی (Q) در مدار برای نمایش تجهیزات کارگاهی وجود ندارد.'),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: outputs.length,
      itemBuilder: (_, i) {
        final q = outputs[i];
        final on = isSimulating && q.value;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFE8F5E9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: on ? Colors.green : Colors.black26,
              width: on ? 2.2 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${q.blockCode}: ${q.label}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (q.equipmentType == EquipmentType.motor)
                RotationTransition(
                  turns: on ? _motorAnim : const AlwaysStoppedAnimation(0),
                  child: Icon(
                    Icons.settings,
                    size: 46,
                    color: on ? Colors.green.shade700 : Colors.grey,
                  ),
                )
              else if (q.equipmentType == EquipmentType.lamp)
                Icon(
                  Icons.lightbulb,
                  size: 46,
                  color: on ? Colors.amber.shade700 : Colors.grey.shade400,
                )
              else if (q.equipmentType == EquipmentType.pump)
                Column(
                  children: [
                    Icon(Icons.water_drop,
                        size: 26, color: on ? Colors.blue : Colors.grey),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 90,
                      child: LinearProgressIndicator(
                        value: tankLevels[q.id] ?? 0.3,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Icon(Icons.sensor_door,
                        size: 30, color: on ? Colors.orange : Colors.grey),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 90,
                      child: LinearProgressIndicator(
                        value: gatePositions[q.id] ?? 0.0,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Text(
                on ? 'روشن / در حال کار' : 'خاموش',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: on ? Colors.green.shade800 : Colors.black45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScopeView() {
    if (scopeHistory.isEmpty) {
      return const Center(
        child: Text(
          'ابتدا SIM (F3) را بزنید تا نمودار زمانی سیگنال‌ها رسم شود.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    final keys = scopeHistory.last.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: keys.length,
      itemBuilder: (_, idx) {
        final label = keys[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF151C26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent)),
              const SizedBox(height: 4),
              SizedBox(
                height: 26,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ScopePainter(
                    samples: scopeHistory.map((m) => m[label] ?? false).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLadderView() {
    final rungs = _convertFbdToLadder();
    final blockMap = {for (var b in blocks) b.id: b};

    if (rungs.isEmpty) {
      return const Center(
        child: Text(
          'حداقل یک خروجی (Q) یا تایمر در مدار قرار دهید.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: rungs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final rung = rungs[i];
        final isPowered =
            isSimulating && (rung.condition?.isActive(blockMap) ?? false);
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isPowered ? Colors.red : Colors.black26,
              width: isPowered ? 2.0 : 1.0,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  color: isSimulating ? Colors.red : Colors.black87,
                ),
                _lineSegment(isPowered),
                if (rung.condition != null)
                  _buildLadNodeWidget(rung.condition!, blockMap)
                else
                  const Text(' [باز] ', style: TextStyle(color: Colors.black38)),
                _lineSegment(isPowered),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isSimulating && rung.targetBlock.value)
                        ? Colors.red.withOpacity(0.15)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: (isSimulating && rung.targetBlock.value)
                          ? Colors.red
                          : Colors.green.shade700,
                    ),
                  ),
                  child: Text(
                    '( ${rung.coilLabel} )',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ),
                _lineSegment(isPowered),
                Container(width: 4, height: 36, color: Colors.black54),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _lineSegment(bool active) {
    return Container(
      width: 16,
      height: 2,
      color: active ? Colors.red : Colors.blue.shade700,
    );
  }

  Widget _buildLadNodeWidget(LadNode node, Map<String, PlcBlock> map) {
    final active = isSimulating && node.isActive(map);
    if (node is LadContact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.red.withOpacity(0.15) : const Color(0xFFF5F5F5),
          border: Border.symmetric(
            vertical: BorderSide(
              color: active ? Colors.red : Colors.black87,
              width: 2,
            ),
          ),
        ),
        child: Text(
          node.inverted ? '/ ${node.label}' : node.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: active ? Colors.red.shade900 : Colors.black87,
          ),
        ),
      );
    } else if (node is LadSeries) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < node.items.length; i++) ...[
            _buildLadNodeWidget(node.items[i], map),
            if (i < node.items.length - 1)
              _lineSegment(isSimulating && node.items[i].isActive(map)),
          ],
        ],
      );
    } else if (node is LadParallel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          border: Border.symmetric(
            vertical: BorderSide(
              color: active ? Colors.red : Colors.black54,
              width: 2,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < node.branches.length; i++) ...[
              _buildLadNodeWidget(node.branches[i], map),
              if (i < node.branches.length - 1) const SizedBox(height: 4),
            ],
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBlockWidget(PlcBlock block) {
    final isSelectedOut = selectedOutputBlockId == block.id;
    final inCount = block.type.inputCount;
    final pinLabels = block.type.pinLabels;
    final bool hasParamBox = block.type.category == BlockCategory.sfTimer ||
        block.type.category == BlockCategory.sfCounter;

    return Positioned(
      left: block.x,
      top: block.y,
      child: GestureDetector(
        onPanUpdate: (isSimulating || isWireTool)
            ? null
            : (details) {
                setState(() {
                  block.x = (block.x + details.delta.dx).clamp(0, 1280);
                  block.y = (block.y + details.delta.dy).clamp(0, 900);
                });
              },
        onTap: () {
          if (isSimulating && block.type == BlockType.input && block.isToggle) {
            setState(() => block.value = !block.value);
          }
        },
        onLongPress: () => _openBlockSettings(block),
        onDoubleTap: () => _openBlockSettings(block),
        child: SizedBox(
          width: blockWidth + 28,
          height: blockHeight + (hasParamBox ? 48 : 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 14,
                top: 0,
                child: SizedBox(
                  width: blockWidth,
                  child: Text(
                    '${block.blockCode} (${block.label})',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  width: blockWidth,
                  height: blockHeight,
                  decoration: BoxDecoration(
                    color: block.type.logoBodyColor,
                    border: Border.all(
                      color: (isSimulating && block.value)
                          ? Colors.red
                          : (isSelectedOut ? Colors.deepOrange : Colors.black87),
                      width: (isSimulating && block.value) || isSelectedOut
                          ? 2.0
                          : 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      block.type.shortName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              // Hanging Parameter Table Box (Ta / T) exactly like Textbook Figure 28!
              if (hasParamBox)
                Positioned(
                  left: 10,
                  top: 14 + blockHeight + 2,
                  child: Container(
                    width: blockWidth + 8,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      border: Border.all(color: Colors.black54, width: 0.9),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ta:', style: TextStyle(fontSize: 8, color: Colors.black87)),
                            Text(
                              block.type == BlockType.ctud
                                  ? '${block.elapsed.toInt()}'
                                  : '${block.elapsed.toStringAsFixed(1)}s',
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(block.type == BlockType.ctud ? 'PV:' : 'T:',
                                style: const TextStyle(fontSize: 8, color: Colors.black87)),
                            Text(
                              block.type == BlockType.ctud
                                  ? '${block.param.toInt()}'
                                  : '${block.param.toStringAsFixed(1)}s',
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              for (int i = 0; i < inCount; i++)
                Positioned(
                  left: 0,
                  top: 14 + _pinY(i, inCount) - 11,
                  child: GestureDetector(
                    onTap: () => _handlePinTap(block.id, false, i),
                    child: Container(
                      width: 24,
                      height: 22,
                      alignment: Alignment.center,
                      child: Container(
                        width: 14,
                        height: 12,
                        decoration: BoxDecoration(
                          color: selectedOutputBlockId != null
                              ? Colors.amber
                              : Colors.white,
                          border: Border.all(color: Colors.black87, width: 1.2),
                        ),
                        child: Center(
                          child: Text(
                            pinLabels[i].substring(0, 1),
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (block.type.hasOutput)
                Positioned(
                  right: 0,
                  top: 14 + (blockHeight / 2) - 11,
                  child: GestureDetector(
                    onTap: () => _handlePinTap(block.id, true, 0),
                    onPanStart: (!isSimulating && isWireTool)
                        ? (_) {
                            setState(() {
                              dragFromBlockId = block.id;
                              dragWireStart = Offset(
                                block.x + 14 + blockWidth + 5,
                                block.y + 14 + (blockHeight / 2),
                              );
                              dragWireCurrent = dragWireStart;
                            });
                          }
                        : null,
                    onPanUpdate: (!isSimulating && isWireTool)
                        ? (d) {
                            setState(() {
                              if (dragWireCurrent != null) {
                                dragWireCurrent = dragWireCurrent! + d.delta;
                              }
                            });
                          }
                        : null,
                    onPanEnd: (!isSimulating && isWireTool)
                        ? (_) {
                            if (dragFromBlockId != null && dragWireCurrent != null) {
                              for (final tb in blocks) {
                                if (tb.id == dragFromBlockId) continue;
                                for (int i = 0; i < tb.type.inputCount; i++) {
                                  final pinPos = Offset(
                                    tb.x + 14 - 5,
                                    tb.y + 14 + _pinY(i, tb.type.inputCount),
                                  );
                                  if ((pinPos - dragWireCurrent!).distance < 28) {
                                    setState(() {
                                      wires.removeWhere((w) =>
                                          w.toBlockId == tb.id && w.toPinIndex == i);
                                      wires.add(PlcWire(
                                        id: _nextId('w'),
                                        fromBlockId: dragFromBlockId!,
                                        toBlockId: tb.id,
                                        toPinIndex: i,
                                      ));
                                    });
                                    break;
                                  }
                                }
                              }
                            }
                            setState(() {
                              dragFromBlockId = null;
                              dragWireStart = null;
                              dragWireCurrent = null;
                            });
                          }
                        : null,
                    child: Container(
                      width: 24,
                      height: 22,
                      alignment: Alignment.center,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: isSelectedOut
                              ? Colors.deepOrange
                              : (isSimulating && block.value
                                  ? Colors.red
                                  : const Color(0xFF00838F)),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black87, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _pinY(int index, int total) {
    if (total == 1) return blockHeight / 2;
    const topPad = 14.0;
    final usable = blockHeight - topPad - 10.0;
    return topPad + (usable / (total - 1)) * index;
  }

  Widget _buildSimIoBar(
    List<PlcBlock> inputs,
    List<PlcBlock> analogInputs,
    bool hasWeekly,
    List<PlcBlock> outputs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: const Color(0xFF1E293B),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Power Failure Simulation Button
            InkWell(
              onTap: _togglePowerOutage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isPowerOutage ? Colors.red : Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isPowerOutage ? 'وصل برق ⚡' : 'قطع برق ⚡',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            if (hasWeekly) ...[
              Text(
                'ساعت: ${simHour.toInt()}:00',
                style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
              ),
              SizedBox(
                width: 100,
                child: Slider(
                  value: simHour,
                  min: 0.0,
                  max: 23.0,
                  divisions: 23,
                  onChanged: (v) => setState(() => simHour = v),
                ),
              ),
            ],
            if (analogInputs.isNotEmpty)
              ...analogInputs.map((ai) => Row(
                    children: [
                      Text('${ai.label}: ${ai.analogVal.toStringAsFixed(1)}V',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.cyanAccent)),
                      SizedBox(
                        width: 100,
                        child: Slider(
                          value: ai.analogVal,
                          min: 0.0,
                          max: 10.0,
                          divisions: 100,
                          onChanged: (v) => setState(() => ai.analogVal = v),
                        ),
                      ),
                    ],
                  )),
            ...inputs.map((inp) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTapDown: inp.isToggle
                      ? null
                      : (_) => setState(() => inp.value = true),
                  onTapUp: inp.isToggle
                      ? null
                      : (_) => setState(() => inp.value = false),
                  onTapCancel: inp.isToggle
                      ? null
                      : () => setState(() => inp.value = false),
                  onTap: inp.isToggle
                      ? () => setState(() => inp.value = !inp.value)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: inp.value ? Colors.green : Colors.blueGrey.shade700,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(inp.label,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              );
            }),
            const SizedBox(width: 10),
            ...outputs.map((out) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: out.value ? Colors.amber : Colors.grey.shade700,
                        boxShadow: out.value
                            ? [const BoxShadow(color: Colors.amber, blurRadius: 6)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(out.label,
                        style: const TextStyle(fontSize: 11, color: Colors.white)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ScopePainter extends CustomPainter {
  final List<bool> samples;
  _ScopePainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final step = size.width / math.max(1, samples.length - 1);
    for (int i = 0; i < samples.length; i++) {
      final x = i * step;
      final y = samples[i] ? 4.0 : size.height - 4.0;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevY = samples[i - 1] ? 4.0 : size.height - 4.0;
        if (prevY != y) path.lineTo(x, prevY);
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScopePainter oldDelegate) => true;
}

class _CheckeredGridAndWirePainter extends CustomPainter {
  final List<PlcBlock> blocks;
  final List<PlcWire> wires;
  final double blockWidth;
  final double blockHeight;
  final bool isSimulating;
  final Offset? dragStart;
  final Offset? dragEnd;

  _CheckeredGridAndWirePainter({
    required this.blocks,
    required this.wires,
    required this.blockWidth,
    required this.blockHeight,
    required this.isSimulating,
    this.dragStart,
    this.dragEnd,
  });

  double _pinY(int index, int total) {
    if (total == 1) return blockHeight / 2;
    const topPad = 14.0;
    final usable = blockHeight - topPad - 10.0;
    return topPad + (usable / (total - 1)) * index;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;
    final majorPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2;

    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        (x % 100 == 0) ? majorPaint : minorPaint,
      );
    }
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        (y % 100 == 0) ? majorPaint : minorPaint,
      );
    }

    final blockMap = {for (var b in blocks) b.id: b};
    for (final w in wires) {
      final fromB = blockMap[w.fromBlockId];
      final toB = blockMap[w.toBlockId];
      if (fromB == null || toB == null) continue;

      final start = Offset(
        fromB.x + 14 + blockWidth + 5,
        fromB.y + 14 + (blockHeight / 2),
      );
      final end = Offset(
        toB.x + 14 - 5,
        toB.y + 14 + _pinY(w.toPinIndex, toB.type.inputCount),
      );

      final isHigh = isSimulating && fromB.value;
      final wirePaint = Paint()
        ..color = isHigh ? Colors.red : Colors.black87
        ..strokeWidth = isHigh ? 2.6 : 1.6
        ..style = PaintingStyle.stroke;

      final midX = (start.dx + end.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(midX, start.dy)
        ..lineTo(midX, end.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(path, wirePaint);

      if (wires.where((x) => x.fromBlockId == w.fromBlockId).length > 1) {
        canvas.drawCircle(
          Offset(midX, start.dy),
          3.2,
          Paint()..color = isHigh ? Colors.red : Colors.black87,
        );
      }
    }

    if (dragStart != null && dragEnd != null) {
      final previewPaint = Paint()
        ..color = Colors.deepOrange
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(dragStart!, dragEnd!, previewPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckeredGridAndWirePainter oldDelegate) => true;
}
