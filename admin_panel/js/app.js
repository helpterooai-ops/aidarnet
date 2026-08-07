// ==========================================================================
// 1) تهيئة فايربيس
// ⚠️ مهم جداً: انسخ نفس قيم firebaseConfig من ملف app.js القديم لديك
// ==========================================================================
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import {
  getAuth, signInWithEmailAndPassword, onAuthStateChanged, signOut
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import {
  getFirestore, doc, writeBatch, serverTimestamp,
  collection, query, where, onSnapshot
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";

const firebaseConfig = {
  // 👇 الصق قيمك الحالية هنا بدون تغيير
  apiKey: "PASTE_YOUR_API_KEY",
  authDomain: "PASTE_YOUR_AUTH_DOMAIN",
  projectId: "PASTE_YOUR_PROJECT_ID",
  storageBucket: "PASTE_YOUR_BUCKET",
  messagingSenderId: "PASTE_YOUR_SENDER_ID",
  appId: "PASTE_YOUR_APP_ID"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

const CATEGORY_COLLECTIONS = {
  "500": "cards_500",
  "1000": "cards_1000",
  "2000": "cards_2000",
  "5000": "cards_5000"
};

// طول رمز الدخول المقبول (رموزك 11 خانة) — رقم التواصل 9 خانات فيُستبعد تلقائياً
const CODE_MIN_LEN = 10;
const CODE_MAX_LEN = 13;

// ==========================================================================
// 2) وحدة الواجهة (توست + سجل + عدادات)
// ==========================================================================
class UIController {
  static showToast(message, type = 'success') {
    const toast = document.getElementById('toast');
    toast.innerText = message;
    toast.className = `toast ${type}`;
    clearTimeout(this._t);
    this._t = setTimeout(() => toast.classList.add('hidden'), 3500);
  }

  static logMessage(wrapper, message) {
    const logBox = wrapper.querySelector('.upload-log-box');
    if (!logBox) return;
    const time = new Date().toLocaleTimeString('ar-EG');
    logBox.innerHTML += `<div>[${time}] ${message}</div>`;
    logBox.scrollTop = logBox.scrollHeight;
  }

  static updateMetricCount(categoryId, count) {
    const element = document.getElementById(`count-category-${categoryId}`);
    if (element) element.innerText = count.toLocaleString('ar-EG');
  }
}

// ==========================================================================
// 3) محرك OCR — استخراج رموز الدخول من الصور وصفحات PDF
// ==========================================================================
class OcrEngine {
  static worker = null;

  static async getWorker(onProgress) {
    if (!this.worker) {
      this.worker = await Tesseract.createWorker('eng', 1, {
        logger: m => { if (m.status === 'recognizing text' && onProgress) onProgress(m.progress); }
      });
    }
    return this.worker;
  }

  // تحويل الأرقام العربية إلى إنجليزية إن وجدت
  static normalizeDigits(text) {
    return text
      .replace(/[٠-٩]/g, d => String('٠١٢٣٤٥٦٧٨٩'.indexOf(d)))
      .replace(/[۰-۹]/g, d => String('۰۱۲۳۴۵۶۷۸۹'.indexOf(d)));
  }

  // استخراج الأكواد: سلسلة 10-13 رقماً (مع السماح بمسافات داخل الرقم من OCR)
  static extractCodes(text) {
    const normalized = this.normalizeDigits(text);
    const chunks = normalized.match(/\d(?:[ ]?\d){9,15}/g) || [];
    const codes = [];
    for (const chunk of chunks) {
      const clean = chunk.replace(/\s/g, '');
      if (clean.length >= CODE_MIN_LEN && clean.length <= CODE_MAX_LEN) codes.push(clean);
    }
    return codes;
  }

  static async recognizeCanvas(canvas, onProgress) {
    const worker = await this.getWorker(onProgress);
    const { data } = await worker.recognize(canvas);
    return this.extractCodes(data.text || '');
  }
}

// ==========================================================================
// 4) معالج الملفات — PDF أو صورة إلى Canvas
// ==========================================================================
class FileProcessor {
  static async toCanvases(file) {
    const canvases = [];
    const isPdf = file.type === 'application/pdf' || file.name.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      const buf = await file.arrayBuffer();
      const pdf = await pdfjsLib.getDocument({ data: buf }).promise;
      for (let p = 1; p <= pdf.numPages; p++) {
        const page = await pdf.getPage(p);
        const viewport = page.getViewport({ scale: 2.5 }); // دقة عالية لقراءة أدق
        const canvas = document.createElement('canvas');
        canvas.width = viewport.width;
        canvas.height = viewport.height;
        await page.render({ canvasContext: canvas.getContext('2d'), viewport }).promise;
        canvases.push(canvas);
      }
    } else {
      const url = URL.createObjectURL(file);
      const img = new Image();
      await new Promise((res, rej) => { img.onload = res; img.onerror = rej; img.src = url; });
      const canvas = document.createElement('canvas');
      canvas.width = img.naturalWidth;
      canvas.height = img.naturalHeight;
      canvas.getContext('2d').drawImage(img, 0, 0);
      URL.revokeObjectURL(url);
      canvases.push(canvas);
    }
    return canvases;
  }
}

// ==========================================================================
// 5) محرك الرفع إلى Firestore (نفس منطقك السابق: دفعات 500)
// ==========================================================================
class FirestoreEngine {
  static async uploadBatch(categoryValue, cards, currentUser, wrapper) {
    const collectionName = CATEGORY_COLLECTIONS[categoryValue];
    if (!collectionName) throw new Error("الفئة المحددة غير صالحة.");

    const BATCH_SIZE = 500;
    const totalCards = cards.length;
    let uploadedCount = 0;

    const progressContainer = wrapper.querySelector('.upload-progress-container');
    const progressBar = wrapper.querySelector('.upload-progress-bar');
    const progressText = wrapper.querySelector('.upload-progress-text');
    progressContainer.classList.remove('hidden');

    for (let i = 0; i < totalCards; i += BATCH_SIZE) {
      const chunk = cards.slice(i, i + BATCH_SIZE);
      const batch = writeBatch(db);
      chunk.forEach(cardCode => {
        const docRef = doc(db, collectionName, cardCode); // معرّف المستند = الكود نفسه (يمنع التكرار نهائياً)
        batch.set(docRef, {
          card: cardCode,
          status: 'available',
          createdAt: serverTimestamp(),
          usedAt: null,
          customerNumber: null,
          userUid: null,
          createdBy: currentUser.uid,
          updatedAt: serverTimestamp()
        });
      });
      await batch.commit();
      uploadedCount += chunk.length;
      const percentage = Math.round((uploadedCount / totalCards) * 100);
      progressBar.style.width = `${percentage}%`;
      progressText.innerText = `${percentage}% (${uploadedCount}/${totalCards})`;
      UIController.logMessage(wrapper, `تم رفع دفعة: ${uploadedCount} من ${totalCards}`);
    }
    return uploadedCount;
  }

  // العدادات اللحظية لكل فئة
  static listenToCategoryMetrics() {
    Object.entries(CATEGORY_COLLECTIONS).forEach(([categoryId, collectionName]) => {
      const q = query(collection(db, collectionName), where('status', '==', 'available'));
      onSnapshot(q, snap => UIController.updateMetricCount(categoryId, snap.size),
        err => console.error("Metrics listener error:", err));
    });
  }
}

// ==========================================================================
// 6) ربط الواجهة: الدخول + الأكورديون + معالجة الملفات + الرفع
// ==========================================================================
const authSection = document.getElementById('auth-section');
const dashboardSection = document.getElementById('dashboard-section');
const userEmailDisplay = document.getElementById('user-email');
const btnLogout = document.getElementById('btn-logout');

onAuthStateChanged(auth, user => {
  if (user) {
    authSection.classList.add('hidden');
    dashboardSection.classList.remove('hidden');
    btnLogout.classList.remove('hidden');
    userEmailDisplay.innerText = user.email;
    FirestoreEngine.listenToCategoryMetrics();
  } else {
    dashboardSection.classList.add('hidden');
    authSection.classList.remove('hidden');
    btnLogout.classList.add('hidden');
    userEmailDisplay.innerText = '--';
  }
});

document.getElementById('login-form').addEventListener('submit', async e => {
  e.preventDefault();
  const email = document.getElementById('login-email').value.trim();
  const password = document.getElementById('login-password').value;
  try {
    await signInWithEmailAndPassword(auth, email, password);
  } catch (err) {
    UIController.showToast('فشل تسجيل الدخول: تحقق من البيانات', 'danger');
  }
});

btnLogout.addEventListener('click', () => signOut(auth));

// ---------- منطق كل فئة ----------
document.querySelectorAll('.category-item-wrapper').forEach(wrapper => {
  const box = wrapper.querySelector('.category-box');
  const inlineForm = wrapper.querySelector('.category-inline-form');
  const fileInput = wrapper.querySelector('.file-input');
  const reportPanel = wrapper.querySelector('.report-panel');
  const codesPreview = wrapper.querySelector('.codes-preview');
  const btnUpload = wrapper.querySelector('.btn-upload');
  const btnReset = wrapper.querySelector('.btn-reset');
  const validBadge = wrapper.querySelector('.valid-count-badge');

  let currentValidCards = [];

  box.addEventListener('click', () => {
    const isActive = wrapper.classList.contains('active');
    document.querySelectorAll('.category-item-wrapper.active')
      .forEach(w => { w.classList.remove('active'); w.querySelector('.category-inline-form').classList.add('hidden'); });
    if (!isActive) {
      wrapper.classList.add('active');
      inlineForm.classList.remove('hidden');
    }
  });

  btnReset.addEventListener('click', () => resetState());

  fileInput.addEventListener('change', async () => {
    const files = Array.from(fileInput.files || []);
    if (!files.length) return;
    resetState();
    UIController.logMessage(wrapper, `بدء معالجة ${files.length} ملف...`);

    const seen = new Set();
    let duplicateCount = 0;
    let invalidPages = 0;

    try {
      for (const file of files) {
        UIController.logMessage(wrapper, `معالجة: ${file.name}`);
        const canvases = await FileProcessor.toCanvases(file);

        for (let i = 0; i < canvases.length; i++) {
          const codes = await OcrEngine.recognizeCanvas(canvases[i],
            p => { /* تقدم التعرف اختياري */ });

          if (codes.length === 0) invalidPages++;

          for (const code of codes) {
            if (seen.has(code)) duplicateCount++;
            else { seen.add(code); currentValidCards.push(code); }
          }
          UIController.logMessage(wrapper, `صفحة/صورة ${i + 1}: استُخرج ${codes.length} كرت`);
        }
      }

      // عرض التقرير
      wrapper.querySelector('.report-valid-count').innerText = currentValidCards.length;
      wrapper.querySelector('.report-duplicate-count').innerText = duplicateCount;
      wrapper.querySelector('.report-invalid-count').innerText = invalidPages;
      codesPreview.innerHTML = currentValidCards.map(c => `<span class="code-chip">${c}</span>`).join('');
      reportPanel.classList.remove('hidden');
      validBadge.innerText = currentValidCards.length;
      btnUpload.disabled = currentValidCards.length === 0;

      if (currentValidCards.length > 0) {
        UIController.showToast(`تم استخراج ${currentValidCards.length} كرت صالح`, 'success');
      } else {
        UIController.showToast('لم يتم العثور على رموز صالحة — جرّب صورة أوضح', 'warning');
      }
    } catch (err) {
      console.error(err);
      UIController.showToast(`فشل المعالجة: ${err.message}`, 'danger');
      UIController.logMessage(wrapper, `خطأ: ${err.message}`);
    } finally {
      fileInput.value = '';
    }
  });

  btnUpload.addEventListener('click', async () => {
    const user = auth.currentUser;
    const categoryValue = wrapper.getAttribute('data-category');
    if (!user) { UIController.showToast('انتهت الجلسة، أعد تسجيل الدخول', 'danger'); return; }
    if (currentValidCards.length === 0) return;

    try {
      btnUpload.disabled = true;
      btnReset.disabled = true;
      UIController.logMessage(wrapper, 'بدء الرفع إلى قاعدة البيانات...');
      const total = await FirestoreEngine.uploadBatch(categoryValue, currentValidCards, user, wrapper);
      UIController.showToast(`تم رفع ${total} كرت إلى فئة ${categoryValue} بنجاح`, 'success');
      UIController.logMessage(wrapper, 'اكتملت العملية 100%.');
      resetState();
    } catch (err) {
      console.error(err);
      UIController.showToast(`فشل الرفع: ${err.message}`, 'danger');
    } finally {
      btnReset.disabled = false;
    }
  });

  function resetState() {
    currentValidCards = [];
    reportPanel.classList.add('hidden');
    codesPreview.innerHTML = '';
    validBadge.innerText = '0';
    btnUpload.disabled = true;
    wrapper.querySelector('.upload-progress-bar').style.width = '0%';
    wrapper.querySelector('.upload-progress-text').innerText = '';
  }
});