import { initializeApp } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-analytics.js";
import { getFirestore, collection, getDocs, query, orderBy, onSnapshot } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";

//Firebase Configuration
const firebaseConfig = {
  apiKey: "AIzaSyA3cIrJ-ai68g6B9VdBeWbviHE19VJnth0",
  authDomain: "herenciapos.firebaseapp.com",
  projectId: "herenciapos",
  storageBucket: "herenciapos.firebasestorage.app",
  messagingSenderId: "889871397832",
  appId: "1:889871397832:web:a6c026123f6912813186fd",
  measurementId: "G-053C3LDW20"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const db = getFirestore(app);
const salesCollectionRef = collection(db, "sales");

// Global variables
let allSales = [];
let filteredSales = [];
        let currentPage = 1;
        let pageSize = 10;
let totalPages = 0;

window.toggleSidebar = function() {
            const sidebar = document.getElementById('sidebar');
    if (sidebar) {
            sidebar.classList.toggle('mobile-visible');
            sidebar.classList.toggle('mobile-hidden');
    }
}

window.toggleSearch = function() {
    const searchBar = document.getElementById('searchBar');
    const searchInput = document.getElementById('searchInput');
    if (searchBar) {
        searchBar.classList.toggle('expanded');
        if (searchBar.classList.contains('expanded')) {
            searchInput.focus();
        }
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

async function initializeDashboard() {
    showLoading(true);
    await loadSalesFromFirebase();
    setupRealtimeOrdersListener();
}

//Load sales from Firebase
async function loadSalesFromFirebase() {
    try {
        console.log("Attempting to load sales from Firebase...");
        const q = query(salesCollectionRef, orderBy("sale_timestamp", "desc"));
        const snapshot = await getDocs(q);
        console.log("Snapshot received:", snapshot.empty ? "No documents" : `${snapshot.size} documents`);
        
        allSales = snapshot.docs.map(doc => {
            const data = doc.data();
            const docId = doc.id;

            let saleTimestamp = data.sale_timestamp;
            let jsDate, dateStr = 'N/A', timeStr = 'N/A';

            if (typeof saleTimestamp === 'number') {
                jsDate = new Date(saleTimestamp);
                dateStr = jsDate.toLocaleDateString();
                timeStr = jsDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            } else {
                console.warn("sale_timestamp is not a number or missing for doc:", docId, data.sale_timestamp);
            }

            let itemsCount = 0;
            if (data.items_json && typeof data.items_json === 'string') {
                try {
                    const itemsArray = JSON.parse(data.items_json);
                    if (Array.isArray(itemsArray)) {
                        itemsCount = itemsArray.reduce((sum, item) => sum + (Number(item.quantity) || 0), 0);
                    } else {
                    }
                } catch (e) {
                }
            } else {
            }
            
            const mappedSale = {
                id: docId,
                customerName: data.cashier_id || 'N/A',
                customerEmail: 'N/A',
                date: dateStr,
                time: timeStr,
                originalTimestamp: saleTimestamp,
                status: data.order_status || 'Completed',
                paymentStatus: data.payment_status || 'Paid',
                paymentMethod: data.order_type || 'N/A',
                items: itemsCount,
                total: data.total_amount !== undefined && data.total_amount !== null ? Number(data.total_amount) : 0,
                ...data 
            };
            return mappedSale;
        });
        applyFiltersAndRender(); 
    } catch (error) {
        console.error("Error loading sales from Firebase: ", error);
        showError("Failed to load sales. Please check Firestore setup and permissions.");
    } finally {
        showLoading(false);
    }
        }

        function renderOrders() {
            const tableBody = document.getElementById('ordersTableBody');
    if (!tableBody) {
        console.error("Table body 'ordersTableBody' not found.");
        return;
    }
    console.log("Rendering orders. CurrentPage:", currentPage, "PageSize:", pageSize, "FilteredSales count:", filteredSales.length);

            const startIndex = (currentPage - 1) * pageSize;
            const endIndex = startIndex + pageSize;
    const salesToShow = filteredSales.slice(startIndex, endIndex);
    console.log("Sales to show on current page:", salesToShow);

    if (salesToShow.length === 0 && !document.getElementById('loadingRow')) { 
                tableBody.innerHTML = `
                    <tr>
                        <td colspan="8" class="empty-state">
                            <i class="fas fa-clipboard-list"></i>
                            <h3>No orders found</h3>
                    <p>Try adjusting your search or filters.</p>
                        </td>
                    </tr>
                `;
    } else if (salesToShow.length > 0) {
        tableBody.innerHTML = salesToShow.map(sale => `
                <tr class="order-row">
                <td><div class="order-id">${sale.id || 'N/A'}</div></td>
                    <td>
                        <div class="customer-info">
                        <div class="customer-name">${sale.customerName || 'N/A'}</div>
                        <div class="customer-email">${sale.customerEmail || 'N/A'}</div>
                        </div>
                    </td>
                    <td>
                    <div>${sale.date || 'N/A'}</div>
                    <div style="color: #64748b; font-size: 12px;">${sale.time || 'N/A'}</div>
                    </td>
                <td><span class="status-badge ${String(sale.status || 'unknown').toLowerCase()}">${capitalizeFirst(sale.status || 'unknown')}</span></td>
                    <td>
                    <span class="payment-badge ${String(sale.paymentStatus || 'unknown').toLowerCase()}">${capitalizeFirst(sale.paymentStatus || 'unknown')}</span>
                    <div style="color: #64748b; font-size: 12px; margin-top: 2px;">${sale.paymentMethod || 'N/A'}</div>
                    </td>
                <td>${sale.items !== undefined ? sale.items : 0} item${(sale.items || 0) !== 1 ? 's' : ''}</td>
                <td><div class="amount">₱${(sale.total !== undefined ? sale.total : 0).toFixed(2)}</div></td>
                <td>
                    <button class="action-btn" onclick="viewOrderDetails('${sale.id}')" title="View Details"><i class="fas fa-eye"></i></button>
                    <!-- CUD buttons for orders would go here -->
                    </td>
                </tr>
            `).join('');
    }
            updateResultsInfo();
    updatePagination();
        }

        function updatePagination() {
    totalPages = Math.ceil(filteredSales.length / pageSize);
    
    const paginationInfo = document.getElementById('paginationInfo');
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
    const pageNumbersContainer = document.getElementById('pageNumbers');

    if (!paginationInfo || !prevBtn || !nextBtn || !pageNumbersContainer) {
        console.warn("One or more pagination elements not found.");
        return;
    }
    
    if (filteredSales.length === 0) {
        paginationInfo.textContent = "Showing 0 to 0 of 0 results";
        pageNumbersContainer.innerHTML = ''; 
        prevBtn.disabled = true;
        nextBtn.disabled = true;
        return;
    }

    const startIndex = Math.max(0, (currentPage - 1) * pageSize + 1);
    const endIndex = Math.min(currentPage * pageSize, filteredSales.length);
    paginationInfo.textContent = `Showing ${startIndex} to ${endIndex} of ${filteredSales.length} results`;

    prevBtn.disabled = currentPage <= 1;
    nextBtn.disabled = totalPages === 0 || currentPage >= totalPages;

    pageNumbersContainer.innerHTML = '';
            const maxVisiblePages = 5;
            let startPage = Math.max(1, currentPage - Math.floor(maxVisiblePages / 2));
    let endPage = Math.min(totalPages || 1, startPage + maxVisiblePages - 1);

    if (totalPages > 0 && endPage - startPage + 1 < maxVisiblePages && endPage === totalPages) {
                startPage = Math.max(1, endPage - maxVisiblePages + 1);
            }

            for (let i = startPage; i <= endPage; i++) {
        if (i === 0 && totalPages > 0) continue; 
                const pageBtn = document.createElement('button');
                pageBtn.className = `pagination-btn ${i === currentPage ? 'active' : ''}`;
                pageBtn.textContent = i;
                pageBtn.onclick = () => goToPage(i);
        pageNumbersContainer.appendChild(pageBtn);
            }
        }

window.goToPage = function(page) {
    if (page < 1 || (page > totalPages && totalPages > 0)) return;
            currentPage = page;
    renderOrders();
        }

window.changePageSize = function(newSize) {
            pageSize = parseInt(newSize);
    currentPage = 1; 
    renderOrders();
        }

        function updateResultsInfo() {
    const resultsInfo = document.getElementById('resultsInfo');
    if (!resultsInfo) return;

    if (filteredSales.length === 0) {
        resultsInfo.textContent = "Showing orders: 0-0 of 0";
        return;
    }
    const startIndex = Math.max(0, (currentPage - 1) * pageSize + 1);
    const endIndex = Math.min(currentPage * pageSize, filteredSales.length);
    resultsInfo.textContent = `Showing orders: ${startIndex}-${endIndex} of ${filteredSales.length}`;
}

function applyFiltersAndRender() {
    console.log("Applying filters and rendering...");
    const searchTerm = document.getElementById('searchInput')?.value.toLowerCase() || '';
    const statusFilter = document.getElementById('statusFilter')?.value || '';
    const paymentFilter = document.getElementById('paymentFilter')?.value || '';
    const dateFilterValue = document.getElementById('dateFilter')?.value || '';
    const amountFilterValue = document.getElementById('amountFilter')?.value || '';
    console.log("Filter values - Search:", searchTerm, "Status:", statusFilter, "Payment:", paymentFilter, "Date:", dateFilterValue, "Amount:", amountFilterValue);

    filteredSales = allSales.filter(sale => {
                const searchMatch = !searchTerm || 
            (sale.id && sale.id.toLowerCase().includes(searchTerm)) ||
            (sale.cashier_id && String(sale.cashier_id).toLowerCase().includes(searchTerm)) ||
            (sale.order_type && sale.order_type.toLowerCase().includes(searchTerm));

        const statusMatch = !statusFilter || (sale.status && sale.status.toLowerCase() === statusFilter.toLowerCase());
        const paymentMatch = !paymentFilter || (sale.paymentStatus && sale.paymentStatus.toLowerCase() === paymentFilter.toLowerCase());

                let dateMatch = true;
        if (dateFilterValue && sale.originalTimestamp) {
            try {
                const orderDateObj = new Date(sale.originalTimestamp);
                orderDateObj.setHours(0,0,0,0);

                    const today = new Date();
                today.setHours(0,0,0,0);

                switch (dateFilterValue) {
                    case 'today': dateMatch = orderDateObj.getTime() === today.getTime(); break;
                        case 'week':
                        const firstDayOfWeek = new Date(today);
                        firstDayOfWeek.setDate(today.getDate() - today.getDay());
                        dateMatch = orderDateObj >= firstDayOfWeek && orderDateObj <= today; 
                            break;
                        case 'month':
                        const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
                        dateMatch = orderDateObj >= firstDayOfMonth && orderDateObj <= today; 
                            break;
                        case 'quarter':
                        const currentQuarter = Math.floor(today.getMonth() / 3);
                        const firstDayOfQuarter = new Date(today.getFullYear(), currentQuarter * 3, 1);
                        dateMatch = orderDateObj >= firstDayOfQuarter && orderDateObj <= today; 
                            break;
                }
            } catch (e) {
                console.warn("Error processing date for filtering sale ID:", sale.id, e);
                dateMatch = false;
            }
        } else if (dateFilterValue && !sale.originalTimestamp) { 
            dateMatch = false;
        }

                let amountMatch = true;
        if (amountFilterValue && typeof sale.total === 'number') {
            const total = sale.total;
            switch (amountFilterValue) {
                case '0-50': amountMatch = total >= 0 && total <= 50; break;
                case '50-100': amountMatch = total > 50 && total <= 100; break;
                case '100-500': amountMatch = total > 100 && total <= 500; break;
                case '500+': amountMatch = total > 500; break;
            }
        }
                return searchMatch && statusMatch && paymentMatch && dateMatch && amountMatch;
            });

    currentPage = 1;
    renderOrders();
}
window.applyFilters = applyFiltersAndRender;

window.clearFilters = function() {
    const searchInput = document.getElementById('searchInput');
    const statusFilter = document.getElementById('statusFilter');
    const paymentFilter = document.getElementById('paymentFilter');
    const dateFilter = document.getElementById('dateFilter');
    const amountFilter = document.getElementById('amountFilter');

    if(searchInput) searchInput.value = '';
    if(statusFilter) statusFilter.value = '';
    if(paymentFilter) paymentFilter.value = '';
    if(dateFilter) dateFilter.value = '';
    if(amountFilter) amountFilter.value = '';
    
    applyFiltersAndRender();
}

window.viewOrderDetails = function(orderId) {
    const sale = filteredSales.find(o => o.id === orderId);
    const modal = document.getElementById('orderDetailsModal');
    const modalContent = document.getElementById('modalOrderDetailsContent');

    if (sale && modal && modalContent) {
        modalContent.innerHTML = `
            <p><strong>Order ID:</strong> ${sale.id || 'N/A'}</p>
            <p><strong>Cashier ID:</strong> ${sale.cashier_id || 'N/A'}</p>
            <p><strong>Date:</strong> ${sale.date || 'N/A'} ${sale.time || ''}</p>
            <p><strong>Order Type:</strong> ${sale.order_type || 'N/A'}</p>
            <p><strong>Status:</strong> ${capitalizeFirst(sale.status || 'unknown')}</p>
            <p><strong>Payment Status:</strong> ${capitalizeFirst(sale.paymentStatus || 'unknown')}</p>
            <p><strong>Items Count:</strong> ${sale.items !== undefined ? sale.items : 'N/A'}</p>
            <p><strong>Total Amount:</strong> $${(sale.total !== undefined ? sale.total : 0).toFixed(2)}</p>
            <p><strong>Sale Timestamp:</strong> ${sale.originalTimestamp || 'N/A'}</p>
            <p><strong>Items JSON:</strong> ${sale.items_json ? `<pre>${JSON.stringify(JSON.parse(sale.items_json), null, 2)}</pre>` : 'N/A'}</p>
            <p><strong>Is Synced:</strong> ${sale.is_synced !== undefined ? sale.is_synced : 'N/A'}</p>
        `;
        modal.style.display = "block";
    } else {
        alert("Sale details not found or modal elements are missing.");
    }
}

// Close modal
window.closeOrderDetailsModal = function() {
    const modal = document.getElementById('orderDetailsModal');
    if (modal) {
        modal.style.display = "none";
    }
}
window.onclick = function(event) {
    const modal = document.getElementById('orderDetailsModal');
    if (event.target == modal) {
        modal.style.display = "none";
    }
}

        function capitalizeFirst(str) {
    if (!str || typeof str !== 'string') return '';
            return str.charAt(0).toUpperCase() + str.slice(1);
        }

let unsubscribeOrdersListener = null; 

// Real-time listener
function setupRealtimeOrdersListener() {
                showLoading(true);
    console.log("Setting up real-time listener for 'sales' collection...");
    const q = query(salesCollectionRef, orderBy("sale_timestamp", "desc"));

    unsubscribeOrdersListener = onSnapshot(q, (snapshot) => {
        console.log("Real-time update received for sales");
        allSales = snapshot.docs.map(doc => {
            const data = doc.data();
            const docId = doc.id;

            let saleTimestamp = data.sale_timestamp;
            let jsDate, dateStr = 'N/A', timeStr = 'N/A';

            if (typeof saleTimestamp === 'number') {
                jsDate = new Date(saleTimestamp);
                dateStr = jsDate.toLocaleDateString();
                timeStr = jsDate.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            }

            let itemsCount = 0;
            if (data.items_json && typeof data.items_json === 'string') {
                try {
                    const itemsArray = JSON.parse(data.items_json);
                    if (Array.isArray(itemsArray)) {
                        itemsCount = itemsArray.reduce((sum, item) => sum + (Number(item.quantity) || 0), 0);
                    }
                } catch (e) {
                    console.error("Error parsing items_json for real-time doc:", docId, e);
                }
            }
            
            return {
                id: docId,
                customerName: data.cashier_id || 'N/A',
                customerEmail: 'N/A',
                date: dateStr,
                time: timeStr,
                originalTimestamp: saleTimestamp,
                status: data.order_status || 'Completed',
                paymentStatus: data.payment_status || 'Paid',
                paymentMethod: data.order_type || 'N/A',
                items: itemsCount,
                total: data.total_amount !== undefined && data.total_amount !== null ? Number(data.total_amount) : 0,
                ...data
            };
        });
        
        applyFiltersAndRender(); 
        showLoading(false); 
                }, (error) => {
        console.error("Error listening to sales: ", error);
        showError("Error connecting to real-time updates for sales.");
        showLoading(false);
                });
        }

        function showLoading(show) {
            const tableBody = document.getElementById('ordersTableBody');
    if(!tableBody) return;
    const loadingRowId = 'loadingRow';
    const existingLoadingRow = document.getElementById(loadingRowId);

            if (show) {
        if (!existingLoadingRow) {
            const loadingRow = tableBody.insertRow(0); 
            loadingRow.id = loadingRowId;
            loadingRow.innerHTML = `
                        <td colspan="8" class="loading">
                    <i class="fas fa-spinner fa-spin"></i>
                            Loading orders...
                        </td>
                `;
        }
    } else {
        if (existingLoadingRow) {
            existingLoadingRow.remove();
        }
            }
        }

        function showError(message) {
            const tableBody = document.getElementById('ordersTableBody');
    if(!tableBody) return;
            tableBody.innerHTML = `
                <tr>
                    <td colspan="8" class="empty-state">
                        <i class="fas fa-exclamation-triangle" style="color: #dc2626;"></i>
                        <h3>Error</h3>
                        <p>${message}</p>
                    </td>
                </tr>
    `
}

window.showUpcomingFeature = function() {
    const overlay = document.getElementById('upcomingFeatureOverlay');
    if (overlay) {
        overlay.classList.add('visible');
        setTimeout(() => {
            const handleClick = () => {
                overlay.classList.remove('visible');
                overlay.removeEventListener('click', handleClick);
            };
            overlay.addEventListener('click', handleClick);
        }, 100);
    }
}

// Add click handlers
document.addEventListener('DOMContentLoaded', function() {
    const pageSizeSelect = document.getElementById('pageSizeSelect');
    if (pageSizeSelect) {
        pageSize = parseInt(pageSizeSelect.value);
        pageSizeSelect.addEventListener('change', (e) => window.changePageSize(e.target.value)); // Ensure global call
    }
    
    initializeDashboard();
    
    // Event Listener for Filter
    const filterControls = {
        'searchInput': 'input',
        'statusFilter': 'change',
        'paymentFilter': 'change',
        'dateFilter': 'change',
        'amountFilter': 'change'
    };

    for (const id in filterControls) {
        const element = document.getElementById(id);
        if (element) {
            element.addEventListener(filterControls[id], applyFiltersAndRender);
        }
    }
    
    const applyBtn = document.querySelector('.filters-section .btn-apply');
    if(applyBtn) applyBtn.addEventListener('click', window.applyFilters);

    const clearBtn = document.querySelector('.filters-section .btn-clear');
    if(clearBtn) clearBtn.addEventListener('click', window.clearFilters);

    const upcomingFeatureLinks = [
        document.querySelector('a[href="#"].nav-item i.fa-chart-bar').parentElement,
        document.querySelector('a[href="#"].nav-item i.fa-question-circle').parentElement,
        document.querySelector('a[href="#"].nav-item i.fa-cog').parentElement
    ];

    upcomingFeatureLinks.forEach(link => {
        if (link) {
            link.addEventListener('click', function(e) {
                e.preventDefault();
                showUpcomingFeature();
            });
        }
    });
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
