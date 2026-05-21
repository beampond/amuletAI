class AmuletInfo {
  final String name;
  final String image;
  final String year;
  final String description;
  final String blessing;
  final String chant;

  const AmuletInfo({
    required this.name,
    required this.image,
    required this.year,
    required this.description,
    required this.blessing,
    required this.chant,
  });
}

const amuletDatabase = {
  'phra_pidta': AmuletInfo(
    name: 'พระปิดตา',
    image: 'assets/amulets/phra_pidta.jpg',
    year: 'สร้างราว พ.ศ. 2400 - 2450',
    description: 'พระปิดตาเป็นพระเครื่องสายเมตตามหานิยม เชื่อกันว่าช่วยป้องกันภัย แคล้วคลาด และเสริมโชคลาภ',
    blessing: 'เด่นด้านเมตตามหานิยม ค้าขายดี แคล้วคลาดปลอดภัย และป้องกันสิ่งไม่ดี',
    chant: 'นะโมพุทธายะ พระปิดตา มหาอุด คงกระพัน',
  ),
  'luang_pho_khun': AmuletInfo(
    name: 'หลวงพ่อคูณ',
    image: 'assets/amulets/luang_pho_khun.jpg',
    year: 'ยุค พ.ศ. 2510 - 2558',
    description: 'พระเครื่องยอดนิยมของหลวงพ่อคูณ ปริสุทโธ วัดบ้านไร่ จังหวัดนครราชสีมา',
    blessing: 'เมตตามหานิยม แคล้วคลาด คุ้มครอง และเสริมโชคลาภ',
    chant: 'นะโมตัสสะ ภะคะวะโต อะระหะโต สัมมาสัมพุทธัสสะ',
  ),
  'luang_pu_thuat': AmuletInfo(
    name: 'หลวงปู่ทวด',
    image: 'assets/amulets/luang_pu_thuat.jpg',
    year: 'สร้างครั้งแรก พ.ศ. 2497',
    description: 'หลวงปู่ทวดเป็นพระเกจิชื่อดัง เชื่อกันว่ามีพุทธคุณด้านแคล้วคลาดและคุ้มครองภัย',
    blessing: 'เด่นด้านแคล้วคลาด คงกระพัน เดินทางปลอดภัย',
    chant: 'นะโม โพธิสัตโต อาคันติมายะ อิติภะคะวา',
  ),
  'somdej': AmuletInfo(
    name: 'พระสมเด็จ',
    image: 'assets/amulets/somdej.jpg',
    year: 'สร้างโดยสมเด็จโต พ.ศ. 2400 เป็นต้นไป',
    description: 'พระสมเด็จได้รับการยกย่องว่าเป็นราชาแห่งพระเครื่องไทย',
    blessing: 'เมตตามหานิยม เสริมบารมี ป้องกันภัย',
    chant: 'อิติปิโส ภะคะวา...',
  ),
  'phra_somdej': AmuletInfo(  // ← alias เผื่อ model ส่งชื่อนี้มา
    name: 'พระสมเด็จ',
    image: 'assets/amulets/somdej.jpg',
    year: 'สร้างโดยสมเด็จโต พ.ศ. 2400 เป็นต้นไป',
    description: 'พระสมเด็จได้รับการยกย่องว่าเป็นราชาแห่งพระเครื่องไทย',
    blessing: 'เมตตามหานิยม เสริมบารมี ป้องกันภัย',
    chant: 'อิติปิโส ภะคะวา...',
  ),
  'phra_khun_pan': AmuletInfo(
    name: 'พระขุนแผน',
    image: 'assets/amulets/phra_khun_pan.jpg',
    year: 'สมัยกรุงศรีอยุธยา',
    description: 'พระขุนแผนมีชื่อเสียงด้านเมตตามหานิยมและเสน่ห์',
    blessing: 'เมตตามหานิยม เสน่ห์ ค้าขายดี',
    chant: 'นะเมตตา โมกรุณา พุทปราณี ธายินดี',
  ),
  'khun_pan': AmuletInfo(     // ← alias
    name: 'พระขุนแผน',
    image: 'assets/amulets/phra_khun_pan.jpg',
    year: 'สมัยกรุงศรีอยุธยา',
    description: 'พระขุนแผนมีชื่อเสียงด้านเมตตามหานิยมและเสน่ห์',
    blessing: 'เมตตามหานิยม เสน่ห์ ค้าขายดี',
    chant: 'นะเมตตา โมกรุณา พุทปราณี ธายินดี',
  ),
  'luang_pho_sothorn': AmuletInfo(
    name: 'หลวงพ่อโสธร',
    image: 'assets/amulets/luang_pho_sothorn.jpg',
    year: 'วัดโสธรวรารามวรวิหาร',
    description: 'พระพุทธรูปศักดิ์สิทธิ์คู่บ้านคู่เมืองของจังหวัดฉะเชิงเทรา',
    blessing: 'คุ้มครองชีวิต การงาน การเงิน และครอบครัว',
    chant: 'นะโมพุทธายะ',
  ),
  'sothorn': AmuletInfo(      // ← alias
    name: 'หลวงพ่อโสธร',
    image: 'assets/amulets/luang_pho_sothorn.jpg',
    year: 'วัดโสธรวรารามวรวิหาร',
    description: 'พระพุทธรูปศักดิ์สิทธิ์คู่บ้านคู่เมืองของจังหวัดฉะเชิงเทรา',
    blessing: 'คุ้มครองชีวิต การงาน การเงิน และครอบครัว',
    chant: 'นะโมพุทธายะ',
  ),
  'luang_pho_ruay': AmuletInfo(
    name: 'หลวงพ่อรวย',
    image: 'assets/amulets/luang_pho_ruay.jpg',
    year: 'วัดตะโก จังหวัดพระนครศรีอยุธยา',
    description: 'พระเกจิชื่อดังด้านโชคลาภ การเงิน และค้าขาย',
    blessing: 'เสริมโชคลาภ เงินทอง ค้าขายรุ่งเรือง',
    chant: 'สัมปะจิตฉามิ',
  ),
  'ruay': AmuletInfo(         // ← alias
    name: 'หลวงพ่อรวย',
    image: 'assets/amulets/luang_pho_ruay.jpg',
    year: 'วัดตะโก จังหวัดพระนครศรีอยุธยา',
    description: 'พระเกจิชื่อดังด้านโชคลาภ การเงิน และค้าขาย',
    blessing: 'เสริมโชคลาภ เงินทอง ค้าขายรุ่งเรือง',
    chant: 'สัมปะจิตฉามิ',
  ),
  'pidta': AmuletInfo(        // ← alias
    name: 'พระปิดตา',
    image: 'assets/amulets/phra_pidta.jpg',
    year: 'สร้างราว พ.ศ. 2400 - 2450',
    description: 'พระปิดตาเป็นพระเครื่องสายเมตตามหานิยม เชื่อกันว่าช่วยป้องกันภัย แคล้วคลาด และเสริมโชคลาภ',
    blessing: 'เด่นด้านเมตตามหานิยม ค้าขายดี แคล้วคลาดปลอดภัย และป้องกันสิ่งไม่ดี',
    chant: 'นะโมพุทธายะ พระปิดตา มหาอุด คงกระพัน',
  ),
  'thuat': AmuletInfo(        // ← alias
    name: 'หลวงปู่ทวด',
    image: 'assets/amulets/luang_pu_thuat.jpg',
    year: 'สร้างครั้งแรก พ.ศ. 2497',
    description: 'หลวงปู่ทวดเป็นพระเกจิชื่อดัง เชื่อกันว่ามีพุทธคุณด้านแคล้วคลาดและคุ้มครองภัย',
    blessing: 'เด่นด้านแคล้วคลาด คงกระพัน เดินทางปลอดภัย',
    chant: 'นะโม โพธิสัตโต อาคันติมายะ อิติภะคะวา',
  ),
};