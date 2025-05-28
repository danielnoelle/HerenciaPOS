import { initializeApp } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-analytics.js";
import { 
    getFirestore,
    collection,
    getDocs,
    addDoc,
    query,
    orderBy,
    serverTimestamp,
    setDoc,
    doc,
    updateDoc,
    deleteDoc
} from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";
import { 
    getAuth,
    createUserWithEmailAndPassword
} from "https://www.gstatic.com/firebasejs/9.23.0/firebase-auth.js";

const firebaseConfig = {
    apiKey: "AIzaSyA3cIrJ-ai68g6B9VdBeWbviHE19VJnth0",
    authDomain: "herenciapos.firebaseapp.com",
    projectId: "herenciapos",
    storageBucket: "herenciapos.firebasestorage.app",
    messagingSenderId: "889871397832",
    appId: "1:889871397832:web:a6c026123f6912813186fd",
    measurementId: "G-053C3LDW20"
};

const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const db = getFirestore(app);
const auth = getAuth(app);
const cashiersCollectionRef = collection(db, "cashiers");

let allCashiers = [];
let filteredCashiers = [];
let currentPage = 1;
let pageSize = 10;
let currentSortColumn = 'name';
let currentSortDirection = 'asc';
let editingCashierId = null;

const tableBody = document.getElementById('cashiersTableBody');
const searchInput = document.getElementById('searchInput');
const statusFilter = document.getElementById('statusFilter');
const dateFilter = document.getElementById('dateFilter');
const sortFilter = document.getElementById('sortFilter');
const resultsInfo = document.getElementById('resultsInfo');
const paginationInfo = document.getElementById('paginationInfo');
const paginationControls = document.getElementById('paginationControls');
const itemsPerPageSelect = document.getElementById('itemsPerPage');
const addCashierModal = document.getElementById('addCashierModal');
const addCashierForm = document.getElementById('addCashierForm');
const cashierNameInput = document.getElementById('cashierNameInput');
const cashierEmailInput = document.getElementById('cashierEmailInput');
const cashierPasswordInput = document.getElementById('cashierPasswordInput');
const passwordFormGroup = document.getElementById('passwordFormGroup');
const cashierFormSubmitButton = document.getElementById('cashierFormSubmitButton');
const modalTitle = addCashierModal ? addCashierModal.querySelector('.modal-title') : null;

document.addEventListener('DOMContentLoaded', () => {
    if (itemsPerPageSelect) {
        pageSize = parseInt(itemsPerPageSelect.value);
        itemsPerPageSelect.addEventListener('change', () => changeItemsPerPage(parseInt(itemsPerPageSelect.value)));
    }
    initializeCashierPage();
});

async function initializeCashierPage() {
    showLoading(true);
    await loadCashiersFromFirestore();
    showLoading(false);
}

async function loadCashiersFromFirestore() {
    try {
        showLoading(true);
        const q = query(cashiersCollectionRef, orderBy('email'));
        const snapshot = await getDocs(q);
        allCashiers = snapshot.docs.map(doc => ({
            id: doc.id, 
            ...doc.data(),
            name: doc.data().name || (doc.data().email ? doc.data().email.split('@')[0] : 'N/A'),
            email: doc.data().email || 'N/A',
            uid: doc.data().uid || doc.id,
            joinedDate: doc.data().joinedDate ? formatDate(doc.data().joinedDate) : 'N/A',
            status: doc.data().status || 'active'
        }));
        applyAllFiltersAndSort();
    } catch (error) {
        console.error("Error loading cashiers from Firestore: ", error);
        showError("Failed to load cashiers.");
    } finally {
        showLoading(false);
    }
}

function renderCashiers() {
    if (!tableBody) return;
    
    const startIndex = (currentPage - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    const cashiersToShow = filteredCashiers.slice(startIndex, endIndex);

    if (cashiersToShow.length === 0 && !document.querySelector('#cashiersTableBody .loading-row')) {
        tableBody.innerHTML = `<tr><td colspan="7" class="empty-state">No cashiers found.</td></tr>`;
    } else {
        tableBody.innerHTML = cashiersToShow.map(cashier => `
            <tr class="order-row"> 
                <td><input type="checkbox" class="order-checkbox" data-id="${cashier.id}"></td>
                <td>${cashier.name}</td>
                <td>${cashier.email}</td>
                <td>${cashier.uid}</td>
                <td>${cashier.joinedDate}</td>
                <td><span class="status-badge ${cashier.status.toLowerCase()}">${capitalizeFirst(cashier.status)}</span></td>
                <td>
                    <button class="action-btn" onclick="editCashier('${cashier.id}')" title="Edit"><i class="fas fa-edit"></i></button>
                    <button class="action-btn" onclick="toggleCashierStatus('${cashier.id}', '${cashier.status}')" title="Toggle Status"><i class="fas ${cashier.status === 'active' ? 'fa-user-slash' : 'fa-user-check'}"></i></button>
                    <button class="action-btn" onclick="deleteCashier('${cashier.id}')" title="Delete"><i class="fas fa-trash"></i></button>
                </td>
            </tr>
        `).join('');
    }
    updateResultsInfo();
    updatePagination();
}

function showLoading(isLoading) {
    if (!tableBody) return;
    const loadingRowClass = 'loading-row';
    let loadingRow = tableBody.querySelector('.' + loadingRowClass);

    if (isLoading) {
        if (!loadingRow) {
            loadingRow = document.createElement('tr');
            loadingRow.className = loadingRowClass;
            loadingRow.innerHTML = `<td colspan="7" class="loading"><i class="fas fa-spinner fa-spin"></i> Loading...</td>`;
            tableBody.insertBefore(loadingRow, tableBody.firstChild);
        }
    } else {
        if (loadingRow) {
            loadingRow.remove();
        }
    }
}

function showError(message) {
    if (!tableBody) return;
    tableBody.innerHTML = `<tr><td colspan="7" class="empty-state"><i class="fas fa-exclamation-triangle"></i> ${message}</td></tr>`;
}

window.openCashierModal = function(cashierId = null) {
    if (!addCashierModal || !addCashierForm || !modalTitle || !cashierNameInput || !cashierEmailInput || !passwordFormGroup || !cashierPasswordInput || !cashierFormSubmitButton) {
        console.error("Modal elements not found");
        return;
    }

    addCashierForm.reset();
    editingCashierId = cashierId;

    if (editingCashierId) {
        modalTitle.textContent = "Edit Cashier";
        const cashier = allCashiers.find(c => c.id === editingCashierId);
        if (cashier) {
            cashierNameInput.value = cashier.name || '';
            cashierEmailInput.value = cashier.email || '';
            cashierEmailInput.readOnly = true;
            passwordFormGroup.style.display = 'none';
            cashierPasswordInput.required = false;
            cashierFormSubmitButton.textContent = "Save Changes";
        } else {
            console.error("Cashier not found for editing");
            closeCashierModal();
            return;
        }
    } else {
        modalTitle.textContent = "Add New Cashier";
        cashierEmailInput.readOnly = false;
        passwordFormGroup.style.display = 'block';
        cashierPasswordInput.required = true;
        cashierFormSubmitButton.textContent = "Add Cashier";
    }
    addCashierModal.classList.add('show');
}

window.closeCashierModal = function() {
    if (addCashierModal) {
        addCashierModal.classList.remove('show');
        editingCashierId = null;
        if (addCashierForm) addCashierForm.reset();
        if (cashierEmailInput) cashierEmailInput.readOnly = false;
        if (passwordFormGroup) passwordFormGroup.style.display = 'block';
        if (cashierPasswordInput) cashierPasswordInput.required = true;
    }
}

window.handleCashierFormSubmit = async function(event) {
    event.preventDefault();
    if (editingCashierId) {
        await updateExistingCashier(editingCashierId);
    } else {
        await addNewCashierToAuthAndFirestore();
    }
}

async function addNewCashierToAuthAndFirestore() {
    const name = cashierNameInput.value;
    const email = cashierEmailInput.value;
    const password = cashierPasswordInput.value;

    if (!name || !email || !password) {
        alert("Name, email, and password are required.");
        return;
    }

    showLoading(true);
    try {
        //Create user in Firebase Authentication
        const userCredential = await createUserWithEmailAndPassword(auth, email, password);
        const user = userCredential.user;
        console.log("User created in Auth:", user.uid);

        //Cashier Document to Firestore
        await setDoc(doc(db, "cashiers", user.uid), {
            uid: user.uid,
            email: user.email,
            name: name,
            status: 'active',
            joinedDate: serverTimestamp()
        });
        console.log("Cashier added to Firestore with UID:", user.uid);
        
        closeCashierModal();
        await loadCashiersFromFirestore();
        alert("Cashier added successfully!");

    } catch (error) {
        console.error("Error adding new cashier: ", error);
        alert(`Error adding new cashier: ${error.message}`);
    } finally {
        showLoading(false);
    }
}

async function updateExistingCashier(cashierId) {
    const name = cashierNameInput.value;
    if (!name) {
        alert("Name is required.");
        return;
    }

    showLoading(true);
    try {
        const cashierDocRef = doc(db, "cashiers", cashierId);
        await updateDoc(cashierDocRef, {
            name: name,
        });
        console.log("Cashier details updated in Firestore for UID:", cashierId);
        
        closeCashierModal();
        await loadCashiersFromFirestore();
        alert("Cashier details updated successfully!");

    } catch (error) {
        console.error("Error updating cashier: ", error);
        alert(`Error updating cashier: ${error.message}`);
    } finally {
        showLoading(false);
    }
}

function applyAllFiltersAndSort() {
    let tempCashiers = [...allCashiers];
    
    const searchTerm = searchInput ? searchInput.value.toLowerCase() : '';
    if (searchTerm) {
        tempCashiers = tempCashiers.filter(c => 
            (c.name && c.name.toLowerCase().includes(searchTerm)) || 
            (c.email && c.email.toLowerCase().includes(searchTerm))
        );
    }

    const statusVal = statusFilter ? statusFilter.value : '';
    if (statusVal) {
        tempCashiers = tempCashiers.filter(c => c.status === statusVal);
    }

    // Sorting
    if (sortFilter && sortFilter.value) {
        const [column, direction] = sortFilter.value.split('-');
        currentSortColumn = column;
        currentSortDirection = direction;
    }

    tempCashiers.sort((a, b) => {
        let valA = a[currentSortColumn];
        let valB = b[currentSortColumn];

        if (typeof valA === 'string') valA = valA.toLowerCase();
        if (typeof valB === 'string') valB = valB.toLowerCase();

        if (valA < valB) return currentSortDirection === 'asc' ? -1 : 1;
        if (valA > valB) return currentSortDirection === 'asc' ? 1 : -1;
        return 0;
    });

    filteredCashiers = tempCashiers;
    currentPage = 1;
    renderCashiers();
}

window.filterCashiers = applyAllFiltersAndSort;
window.applyFilters = applyAllFiltersAndSort;
window.applySorting = applyAllFiltersAndSort;

window.clearFilters = function() {
    if(searchInput) searchInput.value = '';
    if(statusFilter) statusFilter.value = '';
    if(dateFilter) dateFilter.value = '';
    if(sortFilter) sortFilter.value = 'date-desc';
}

window.sortTable = function(column) {
    if (currentSortColumn === column) {
        currentSortDirection = currentSortDirection === 'asc' ? 'desc' : 'asc';
    } else {
        currentSortColumn = column;
        currentSortDirection = 'asc';
    }
    if (sortFilter) {
        sortFilter.value = `${currentSortColumn}-${currentSortDirection}`;
    }
    applyAllFiltersAndSort();
}

function updateResultsInfo() {
    if (!resultsInfo) return;
    resultsInfo.textContent = `Showing ${filteredCashiers.length > 0 ? (currentPage - 1) * pageSize + 1 : 0}-${Math.min(currentPage * pageSize, filteredCashiers.length)} of ${filteredCashiers.length} cashiers`;
}

function updatePagination() {
    if (!paginationControls || !paginationInfo) return;
    const totalPages = Math.ceil(filteredCashiers.length / pageSize);
    paginationControls.innerHTML = '';

    if (totalPages <= 1) {
        paginationInfo.textContent = `Showing ${filteredCashiers.length} cashiers`;
        return;
    }
    
    paginationInfo.textContent = `Showing ${(currentPage - 1) * pageSize + 1} to ${Math.min(currentPage * pageSize, filteredCashiers.length)} of ${filteredCashiers.length} results`;

    const prevButton = document.createElement('button');
    prevButton.className = 'pagination-btn';
    prevButton.innerHTML = '<i class="fas fa-chevron-left"></i> Previous';
    prevButton.disabled = currentPage === 1;
    prevButton.onclick = () => goToPage(currentPage - 1);
    paginationControls.appendChild(prevButton);

    for (let i = 1; i <= totalPages; i++) {
        const pageButton = document.createElement('button');
        pageButton.className = `pagination-btn ${i === currentPage ? 'active' : ''}`;
        pageButton.textContent = i;
        pageButton.onclick = () => goToPage(i);
        paginationControls.appendChild(pageButton);
    }

    const nextButton = document.createElement('button');
    nextButton.className = 'pagination-btn';
    nextButton.innerHTML = 'Next <i class="fas fa-chevron-right"></i>';
    nextButton.disabled = currentPage === totalPages;
    nextButton.onclick = () => goToPage(currentPage + 1);
    paginationControls.appendChild(nextButton);
}

window.goToPage = function(page) {
    currentPage = page;
    renderCashiers();
}

window.changeItemsPerPage = function(newSize) {
    pageSize = parseInt(newSize);
    currentPage = 1;
    applyAllFiltersAndSort();
}

window.exportCashiersCSV = function() {
    if (filteredCashiers.length === 0) {
        alert("No cashiers to export.");
        return;
    }
    let csvContent = "data:text/csv;charset=utf-8,";
    
    csvContent += "UID,Name,Email,Joined Date,Status\r\n";
    filteredCashiers.forEach(cashier => {
        const row = [
            `"${cashier.uid || ''}"`, 
            `"${cashier.name || ''}"`, 
            `"${cashier.email || ''}"`, 
            `"${cashier.joinedDate || ''}"`, 
            `"${cashier.status || ''}"`
        ].join(",");
        csvContent += row + "\r\n";
    });

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", "cashiers_export.csv");
    document.body.appendChild(link); 
    link.click();
    document.body.removeChild(link);
}

function formatDate(timestamp) {
    if (!timestamp) return 'N/A';
    if (timestamp.seconds) {
        return new Date(timestamp.seconds * 1000).toLocaleDateString();
    }
    try {
        return new Date(timestamp).toLocaleDateString();
    } catch (e) {
        return 'Invalid Date';
    }
}

function capitalizeFirst(str) {
    if (!str || typeof str !== 'string') return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

window.editCashier = function(cashierId) {
    openCashierModal(cashierId);
}

window.toggleCashierStatus = async function(cashierId, currentStatus) {
    if (!cashierId) {
        console.error("No cashier ID provided for status toggle.");
        alert("Could not toggle status: Cashier ID missing.");
        return;
    }

    const newStatus = currentStatus === 'active' ? 'disabled' : 'active';
    const confirmToggle = confirm(`Are you sure you want to change status of cashier ${cashierId} to ${newStatus}?`);

    if (confirmToggle) {
        showLoading(true);
        try {
            const cashierDocRef = doc(db, "cashiers", cashierId);
            await updateDoc(cashierDocRef, { 
                status: newStatus 
            });
            console.log(`Cashier ${cashierId} status changed to ${newStatus}`);
            alert(`Cashier status successfully updated to ${newStatus}.`);
            await loadCashiersFromFirestore();
        } catch (error) {
            console.error("Error toggling cashier status: ", error);
            alert(`Failed to update cashier status: ${error.message}`);
        } finally {
            showLoading(false);
        }
    }
}

window.deleteCashier = async function(cashierId) {
    if (!cashierId) {
        console.error("No cashier ID provided for deletion.");
        alert("Could not delete cashier: Cashier ID missing.");
        return;
    }

    const cashierToDelete = allCashiers.find(c => c.id === cashierId);
    const cashierIdentifier = cashierToDelete ? (cashierToDelete.name || cashierToDelete.email) : cashierId;

    if (!confirm(`Are you sure you want to delete cashier ${cashierIdentifier} from the list? This will remove their record from the cashier database, but their authentication account will remain active and require manual deletion via Firebase console or Admin SDK.`)) {
        return;
    }

    showLoading(true);
    try {
        const cashierDocRef = doc(db, "cashiers", cashierId);
        await deleteDoc(cashierDocRef);
        
        console.log(`Cashier document ${cashierId} deleted from Firestore.`);
        alert(`Cashier ${cashierIdentifier} has been removed from the list.\nIMPORTANT: Their authentication account has NOT been deleted. This must be done manually via the Firebase console or a backend process.`);
        
        await loadCashiersFromFirestore();

    } catch (error) {
        console.error("Error deleting cashier from Firestore: ", error);
        alert(`Failed to delete cashier from list: ${error.message}`);
    } finally {
        showLoading(false);
    }
}

window.toggleAllCashiers = function(checkbox) {
    const checkboxes = document.querySelectorAll('#cashiersTableBody .order-checkbox');
    checkboxes.forEach(cb => cb.checked = checkbox.checked);
    
}

window.toggleSidebar = function() {
    const sidebar = document.getElementById('sidebar');
    if (sidebar) {
        sidebar.classList.toggle('mobile-visible');
        sidebar.classList.toggle('mobile-hidden');
    }
}
document.addEventListener('click', function(event) {
    const sidebar = document.getElementById('sidebar');
    const mobileMenuBtn = document.querySelector('.mobile-menu-btn'); 
    if (window.innerWidth <= 768 && sidebar && mobileMenuBtn) {
        if (!sidebar.contains(event.target) && !mobileMenuBtn.contains(event.target)) {
            sidebar.classList.add('mobile-hidden');
            sidebar.classList.remove('mobile-visible');
        }
    }
});
window.addEventListener('resize', function() {
    if (window.innerWidth > 768) {
        const sidebar = document.getElementById('sidebar');
        if (sidebar) { 
            sidebar.classList.remove('mobile-visible');
            sidebar.classList.add('mobile-hidden');
        }
    }
}); 