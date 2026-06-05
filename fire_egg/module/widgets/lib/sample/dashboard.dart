import 'package:flutter/material.dart';

class EggCrackDetectorPage extends StatelessWidget {
  const EggCrackDetectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> detected = [
      {'id': 'CR-250403-001', 'time': '2026-04-03 07:21:13', 'pos': '3열-2번', 'conf': '96%'},
      {'id': 'CR-250403-002', 'time': '2026-04-03 07:22:48', 'pos': '3열-4번', 'conf': '94%'},
      {'id': 'CR-250403-003', 'time': '2026-04-03 07:24:06', 'pos': '4열-1번', 'conf': '98%'},
      {'id': 'CR-250403-004', 'time': '2026-04-03 07:25:22', 'pos': '4열-3번', 'conf': '91%'},
      {'id': 'CR-250403-005', 'time': '2026-04-03 07:26:41', 'pos': '5열-2번', 'conf': '95%'},
    ];

    final List<Map<String, String>> devices = [
      {'id': 'DET-1001', 'name': '파각란검출기 1호기', 'conn': 'Wi-Fi 연결', 'status': '검사중', 'eggs': '1,248', 'cracks': '37', 'sync': '정상'},
      {'id': 'DET-1002', 'name': '파각란검출기 2호기', 'conn': '유선 포트 연결', 'status': '대기', 'eggs': '982', 'cracks': '21', 'sync': '정상'},
      {'id': 'DET-1003', 'name': '파각란검출기 3호기', 'conn': 'Wi-Fi 연결', 'status': '오프라인', 'eggs': '-', 'cracks': '-', 'sync': '점검 필요'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // slate-100
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Stats Section
                _buildHeaderStats(),
                const SizedBox(height: 24),

                // Main Content
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 1024) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 280, child: _buildDeviceSidebar(devices)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildMainContent(detected)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildDeviceSidebar(devices),
                          const SizedBox(height: 24),
                          _buildMainContent(detected),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 상단 헤더 및 통계 카드
  Widget _buildHeaderStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 20,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('파각란검출기별 송신 데이터 관리 웹페이지', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              SizedBox(height: 8),
              Text('장비별 데이터 송신 현황, 실시간 검출 화면, 파각란 이미지 이력을 통합 관리하는 예시 화면', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          Wrap(
            spacing: 12,
            children: [
              _statTile('전체 장비', '3'),
              _statTile('연결 정상', '2'),
              _statTile('오늘 처리란', '2,230'),
              _statTile('오늘 파각란', '58'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 왼쪽 장비 목록 사이드바
  Widget _buildDeviceSidebar(List<Map<String, String>> devices) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('장비 목록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...devices.asMap().entries.map((entry) {
            int idx = entry.key;
            var d = entry.value;
            bool isFirst = idx == 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isFirst ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isFirst ? Colors.black : Colors.grey.shade200, width: isFirst ? 1.5 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('ID: ${d['id']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Text(d['status']!, style: const TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _deviceInfoText('연결 방식: ${d['conn']}'),
                  _deviceInfoText('처리란: ${d['eggs']} 개/일'),
                  _deviceInfoText('파각란: ${d['cracks']} 개/일'),
                  _deviceInfoText('동기화: ${d['sync']}'),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _deviceInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
    );
  }

  // 메인 대시보드 영역
  Widget _buildMainContent(List<Map<String, String>> detected) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildLiveView()),
                  const SizedBox(width: 24),
                  Expanded(flex: 1, child: _buildSettingsPanel()),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildLiveView(),
                  const SizedBox(height: 24),
                  _buildSettingsPanel(),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        _buildHistoryGrid(detected),
      ],
    );
  }

  // 실시간 카메라 뷰 섹션
  Widget _buildLiveView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('실시간 검출 화면', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('검출 박스, 판정 결과, 검사 진행 상태를 실시간 표시', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // 가상 배경 그라데이션
                    Container(
                      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD8D8D8), Color(0xFFF5F5F5)])),
                    ),
                    // 오버레이 정보
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.black.withOpacity(0.55),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Camera A Live View', style: TextStyle(color: Colors.white, fontSize: 12)),
                            Text('2026-04-03 07:25:18', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    // 검출 박스 예시 (좌표는 JSX 기준 비례값)
                    _detectorBox(left: 0.08, top: 0.28, color: Colors.limeAccent, label: 'Normal 99%'),
                    _detectorBox(left: 0.34, top: 0.32, color: Colors.red, label: 'Crack 96%', isCrack: true),
                    _detectorBox(left: 0.61, top: 0.30, color: Colors.limeAccent, label: 'Normal 98%'),
                    // 하단 바
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(16)),
                        child: const Text('검사 위치: 4열 / 6열 | 현재 배치: LOT-20260403-01', style: TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detectorBox({required double left, required double top, required Color color, required String label, bool isCrack = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              left: constraints.maxWidth * left,
              top: constraints.maxHeight * top,
              child: Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 4),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * left + 2,
              top: constraints.maxHeight * top - 25,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isCrack ? Colors.white : Colors.black),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 우측 설정 패널
  Widget _buildSettingsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('송신 데이터 / 설정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('자동 반영되며, 관리자 권한으로 수정 가능', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          _settingItem('검출기 ID', 'DET-1001'),
          _settingItem('처리란 개수 (개/일)', '1,248'),
          _settingItem('파각란 개수 (개/일)', '37'),
          _settingItem('설정 시간', '2026:04:03:07:25:18'),
          _settingItem('마지막 송신 시각', '2026-04-03 07:25:20'),
          const SizedBox(height: 16),
          const Text('데이터 송신 방식', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              _button('Wi-Fi', true),
              const SizedBox(width: 12),
              _button('유선 포트', false),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _actionBtn('저장', isPrimary: true),
              _actionBtn('수정'),
              _actionBtn('일일 초기화'),
              _actionBtn('장비 동기화'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _settingItem(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _button(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: active ? Colors.black : Colors.grey.shade200, width: active ? 2 : 1),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.black : Colors.grey),
      ),
    );
  }

  Widget _actionBtn(String text, {bool isPrimary = false}) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF0F172A) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(color: isPrimary ? Colors.white : Colors.black, fontWeight: FontWeight.w500, fontSize: 13),
      ),
    );
  }

  // 하단 이미지 이력 그리드
  Widget _buildHistoryGrid(List<Map<String, String>> detected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('파각란 검출 이미지 이력', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('최근 검출된 파각란 사진을 시간순으로 나열', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                child: const Text('총 37건', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 1000 ? 5 : (constraints.maxWidth > 600 ? 2 : 1);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: detected.length,
                itemBuilder: (context, index) {
                  var item = detected[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(colors: [Color(0xFFE7E7E7), Color(0xFFCFCFCF)]),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Container(
                                    width: 60,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.red, width: 3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                    child: const Text(
                                      'Crack',
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('#${index + 1} ${item['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 4),
                        _historySmallText('시간: ${item['time']}'),
                        _historySmallText('위치: ${item['pos']}'),
                        _historySmallText('신뢰도: ${item['conf']}'),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _historySmallText(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)));
  }
}
