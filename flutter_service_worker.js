'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "f393d3c16b631f36852323de8e583132",
"manifest.json": "664caf8b2e29395c77a244ca2f02d135",
"index.html": "aa82a650ac04c66e019e0a5b035aadb4",
"/": "aa82a650ac04c66e019e0a5b035aadb4",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "5813b1b9cc756fd7d404df1ec257f295",
"assets/assets/icons/icon.png": "eb11fd097199c3e7c7ebb7319cbb2037",
"assets/assets/icons/icon-original.png": "a3ce076ac7962cdeee3862c4a6cb51ae",
"assets/assets/icons/palette.png": "808246950e1dfa115c5edd597c280a22",
"assets/assets/images/cake_3.png": "afb02439ecc87f8c3fbb7352ed602598",
"assets/assets/images/cake_2.png": "0ba30bfb7e32c41d31b52609ffcd8780",
"assets/assets/images/cake_1.png": "6c8047081c308dd63ffa3bdde33e6fd6",
"assets/assets/cake_layers/full_view/heartshaped/2layers/vanilla.glb": "40bd93766124d3237cbc06be64f26628",
"assets/assets/cake_layers/full_view/heartshaped/2layers/ube.glb": "9172e4558f574a30b4e159da26b92863",
"assets/assets/cake_layers/full_view/heartshaped/2layers/chocolate.glb": "b7fbcded55dc489790bb838e95e9b35c",
"assets/assets/cake_layers/full_view/roundshaped/2layers/vanilla.glb": "58b99037c1ffab71714b883ea8f48097",
"assets/assets/cake_layers/full_view/roundshaped/2layers/ube.glb": "7d743ee79a3233902bdf2be6e87f7964",
"assets/assets/cake_layers/full_view/roundshaped/2layers/chocolate.glb": "e1d5985a9db56328d0a7028c3989e7b9",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/UCC.glb": "8aab9b12a6c4ce6187e5f9a891f2609a",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/VUV.glb": "ec94add1b5b2ebeac0c6cca4d30f6a3a",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/UVC.glb": "1bccbabdc74b21fce0cec3f41a55a858",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/VUC.glb": "88401a1f85fd62c61396a37a89fa08b3",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/CCV.glb": "4e26aa833725707cb414ed7a72b5d99c",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/VVC.glb": "aa4fac0fe9c37ff3b97b7a24282a5c79",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/UVU.glb": "839a24664514f76ec800006b831bd367",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/UCU.glb": "2d63548dfb38593c7d76de9467e26874",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/UUC.glb": "543a50c966f9627a4b9aa1a98e3bf877",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/VUU.glb": "20f920fac19a55120b47fff7f56b920b",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/CVV.glb": "030b96ab185732a1cc2befc3649d72fe",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/CCC.glb": "935e810cb9f2420621959b59e39eedc7",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/UVV.glb": "cb5354b862ec745da298a9dfc0ec766a",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/CUC.glb": "0c05715c2d754fde6ecaa195f4777704",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/CVU.glb": "d2f33b3e9e8ecb550808738e94733915",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/CVC.glb": "2c5ce497d5f492601cb99eacf4b4061f",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/UCV.glb": "6f52c44096d4d40b4236db66d2444713",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/VVU.glb": "9efc7b2bb790bc15ab506cd6052df301",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/UUU.glb": "45db645b6e5f1da0abd4516d5fda46ee",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/VCC.glb": "57d8f9ce9387e2e2e4cabaa443735f98",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/CUU.glb": "5eb098451e03938487039dd9ce5f16e1",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/VCV.glb": "40611afcbb3909b305c1f858e50b6d59",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/CUV.glb": "cf1cbd1124ddff66f5bc263490a2f4a5",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/CCU.glb": "2ff3da0982fc12d231e662cdd0f73fc2",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/VVV.glb": "8d53f16e975e676fe5fd23dfadb4e746",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/VCU.glb": "d44690ba6d93ee0339263410170c4d33",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/stacked/UUV.glb": "29081e8a7007ba373789e50c9b6fa3b3",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/UCC.glb": "b05a0f663c233f69ba7554b875e1f2f5",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/VUV.glb": "a0ff7215fa96ebdb1ee819fcecec5f1a",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/UVC.glb": "a1a3edf415e1e9abd00f50b38262b9f4",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/VUC.glb": "41a916b983c161f570cd58349b55b9ca",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/CCV.glb": "9f9bf1cae31637938a828dc39756cf5c",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/VVC.glb": "7fdb4f781b9affd91018506f23318f1c",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/UVU.glb": "84933e11bb7a60848c32c3d0fb4844c3",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/UCU.glb": "2709ba9b2e4d2fb451b8d1dcafaf235b",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/UUC.glb": "0c19e3afdc0c7256ff4b2ae8496234b8",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/VUU.glb": "76d7922b836c203189a5f031c5092776",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/CVV.glb": "6ea387175a9fdab34dff288383caba24",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/CCC.glb": "b7aa1cf34fab9e9ec4d92d31cfef9b78",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/UVV.glb": "2d3aee66fd64ba70141d4c5d49ee7991",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/CUC.glb": "f87cc3cad513aa4c8cce20faa9386126",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/CVU.glb": "41477a81ef99480f97fe522fdea1f8a1",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/CVC.glb": "aaa1ef72e2bdfb05bcbe1651ecc29791",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/UCV.glb": "1b9fe2d8596adb65701decd66fb65ce3",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/VVU.glb": "a4133a4271f122200d717d0eb929d174",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/UUU.glb": "8638cb59e491af28f752f538f495912a",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/VCC.glb": "54b685b1ac9eb8d0e264349abc22263f",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/CUU.glb": "f8a078f35323cb5fd492fd478f3a2370",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/VCV.glb": "a9b749ef159f883e294324669c9f9049",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/CUV.glb": "75104b7625b56ceab7d34e400ed9e8d2",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/CCU.glb": "f03c2cde2da4f4f0ebf5abefc60cead9",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/VVV.glb": "0abc04f32923691f8704e63e3f3187f0",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/VCU.glb": "e6dfff5dde4ff295c262772a24d40814",
"assets/assets/cake_layers/layer_view/heartshaped/2layers/seperate/UUV.glb": "147ea34b9f295b5e3c988f9b119c8c98",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/UCC.glb": "5e9d6a127511ea7b45c03559e2cc8645",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/VUV.glb": "21a0e2375562da71520a1af685272129",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/UVC.glb": "7f2e1f7808c38302b3a7f745601e102d",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/VUC.glb": "861c9024f154832c140bbc3357e3c141",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/CCV.glb": "5cf3b9193ffcd9e19a1752ff442a9c9b",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/VVC.glb": "025d158b422c84873ffc6c319538898b",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/UVU.glb": "4f5ad155aeefc49e1bea0bcc07046568",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/UCU.glb": "c92d56522dba6fb75e84e40e4426c44d",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/UUC.glb": "87212604435404090613a8d4e1f921aa",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/VUU.glb": "34b22e8b08857ae6bc6ff6dfa4de86e7",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/CVV.glb": "ad7544f612803dfe07da033949172629",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/CCC.glb": "4ba7b6571d67d65212d1210d908ae7da",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/UVV.glb": "7c28d0cf9d5a0b39166520e3fa0bce88",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/CUC.glb": "cd5d17eced292721e63635fb21e94fea",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/CVU.glb": "282d3a2598b1e07bb41cd7f77712a8e4",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/CVC.glb": "4720ec0b836354de24c9f949e42ee33c",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/UCV.glb": "6bf72bb4aaad9f7999a89f98b5c5102b",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/VVU.glb": "335caa51c36d6f2edaae77eaee2eebd0",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/UUU.glb": "72fc66093fe64d0a20f553889173b70f",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/VCC.glb": "f5401ecca96bf61eb617ec48a428c526",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/CUU.glb": "1e76404ade1859e9736a632e290306c8",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/VCV.glb": "800a48ecd1145e96dfbf64a2caa8794b",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/CUV.glb": "886924f23b01e2dfa680f727a03d3132",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/CCU.glb": "20a7a402ec3f91ba4b5be00dada9aab5",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/VVV.glb": "0d6765660b9339cb3cc005efd925a823",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/VCU.glb": "4c1d5f4da4685a239bd07d2527370055",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/stacked/UUV.glb": "0c2eceeba4902bdf4cf0f42490fa2828",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/UCC.glb": "4bbb5ef0c105bff85a384125894ff2af",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/VUV.glb": "c15a4a983ec15080432d70e1c0819dcb",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/UVC.glb": "7986de34a172ab5196930a42d79f512e",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/VUC.glb": "b7619a484ba73068401fb52833a525fe",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/CCV.glb": "8f239613fa6993d88ce7867ced632e1c",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/VVC.glb": "89a7ebae04463ce4c4697a6d7d4fa032",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/UVU.glb": "d0ac898a31e89c71cec596539f1a93ba",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/UCU.glb": "c2b1af27da4e78dd7c0655d235cb97c5",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/UUC.glb": "6b5b62f6c46e3a9ecc1657cc126078ab",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/VUU.glb": "bf82c5b653863a463a30c5aff1b80e5b",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/CVV.glb": "4d9a586de93b3b52f2f395f4fae4f997",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/CCC.glb": "e83efe461e432df880ca7cce438f432b",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/UVV.glb": "b437b5cae94477b1e917a093e804e79d",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/CUC.glb": "16e148273a35f737fb437f1601d978c6",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/CVU.glb": "6b90f66b600c4e5b2659a68134dff935",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/CVC.glb": "4ae190c10c451bca419533fb1c34b53d",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/UCV.glb": "a79115d9d3522a18d5060df9d83cdb3a",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/VVU.glb": "8256e4804413cf5721d6d67776be0ae5",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/UUU.glb": "e62e87fa8a13d12d0191b68a974ba760",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/VCC.glb": "fe132a59b493fc00437959b3ec209d6c",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/CUU.glb": "c177f4b3b608b5c3e4c989564554f550",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/VCV.glb": "dc12bf866f2e400b36f0e7f199c516e1",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/CUV.glb": "9d681228e7d2a9dd0bbc15be49a3a9b5",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/CCU.glb": "4543c7c0b92012d21393bba95d30565f",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/VVV.glb": "74afdc9acedaef06c7954433eb9c8040",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/VCU.glb": "123a0ef02551bca9dc491a0f0078526c",
"assets/assets/cake_layers/layer_view/roundshaped/2layers/seperate/UUV.glb": "0bf400cc2b13fdf88a5c1ac82fbee973",
"assets/fonts/MaterialIcons-Regular.otf": "63e25e8a5a1c4a5983ee7b1523ad1868",
"assets/NOTICES": "342f17a5e44a25db505adc2f8d2839ad",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/packages/model_viewer_plus/assets/template.html": "8de94ff19fee64be3edffddb412ab63c",
"assets/packages/model_viewer_plus/assets/model-viewer.min.js": "a9dc98f8bf360be897a0898a7395f905",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin": "1041b7f7babc9e6aaa53d73d1796e626",
"assets/AssetManifest.json": "a7d968bbe4c579b85db12db73cfc07aa",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/chromium/canvaskit.js": "671c6b4f8fcc199dcc551c7bb125f239",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"canvaskit/skwasm.js": "694fda5704053957c2594de355805228",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/canvaskit.js": "66177750aff65a66cb07bb44b8c6422b",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icon_nobg.png": "7ee13267ad24f03d13268ff06e047cb3",
"flutter_bootstrap.js": "ac4dcf4816746665c653dcbc47b0b489",
"version.json": "5e9a8edcf5d69685c40ff8b00b270ec5",
"main.dart.js": "c15b76cfd8f37e3c670da6293b685b45"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
