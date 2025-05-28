import { initializeApp } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/9.23.0/firebase-analytics.js";
import { 
    getFirestore,
    collection,
    getDocs,
    doc,
    setDoc,
    updateDoc,
    deleteDoc,
    query,
    orderBy,
    serverTimestamp
} from "https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore.js";

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
const db = getFirestore(app);
const menuCollectionRef = collection(db, "menu");

const DROPBOX_ACCESS_TOKEN = "sl.u.AFxf2xS8K6eOodowUZQDpd-I4XLtbIwtKiFe-8LPY4eZ6ATbiGogy9SGryKEnLcwuYTTfgGPx-uz0t1QFv646_Sjlr3CTuhzCbTaoz0L4J-WIndoMS_TbsWnZoT1pxsBPfj9QKSGcx_ztr5wAeRrRklV7qbnao8r_wo3GZEBGGVKoPx9WfOG6cQ1Byg3Y9fRSbsrp23Z0Pg2TM5oDAkO6auUKepOvJTI5WOvkRbBESZJHlbM3elQLZejVsYc6p-JWV6-hGjdYxOMH9QbQxplvfkTKSRWFsgd6bb_blVwRUTTNMdiRZnK7th6KjrH8yKvKMK7KJBoXgA-Oy64noZB_cd0WgNOskT3ryC1yIfEkPnKf2dt6Y2WY9hYotjd9uOQRQJIKMO9HIGeu1A4fyY8RR2iAJyTuu8dhM7uMWEVib2QE_1BGMXrywOa3T9ZOtOOIV9E_ZA2CnTTAdlFmMmnMfkMgafXYOeulqpKgsnldLfJl70w0BjpOm5iYD7a13NjkRJNyX1UqRnxTJSRPQfdQmSbL5m4GYOVkgpO3Krr5Z3ZSwJbA0GFfgdkW1qbv6epKqHZm45iyouSFN1lJN9W7Miqrn9vD29ZsYlexv9bRdobOsA92A_bmeiaZ705y_RbAhQQ_CtAcuNXm9_HRLvdHfrvZf-Dqbfq47UKQicHffxHbaTwXeXDEAecTmwxyEO3PxFpX5t1Pqw2zLatSo0m-DL-WUC7EhXGHCc0gzKt9HdCcK78hKJq-MQDHxnJN5dQxEeAAbHEyE5XDcuV-R4msvuVK1ZdMiDRrf-eqb-khJN34iHgkYRIKTW0YyXi1WDNfclnwTWXNXGRK1h6JOK3z3Xq3ZNbw3WJLvDzGOt5njGiMh8uMzaaH1ux7blFlqGn1P2_CbELPUPwFdflRKO8oDJ4av774ql_bXjJ-BubUa_wuArGHECDC-67IKSTVjfwScCj-1jCb63U0nZHM4DzLhQiIJ0e72AwdBhIbif8RoEa8piFu_VTa6d9uz4E38nnj6QosqH9daqqswJq0RlaK-iCaE6uyyuGrFI3e2oc1XrZvfTWXEX5k6qgyPzrzyOn3BiIsLHX4SBXZjqA8E3WmkV4oPgFopTMFOsT8hVovgn9A_xbAEAyCKDCD_Y9QeBY_w3qB5UD7ubbOeKH8gBVBWeRIsPuTVFzMQsmu9_WJ2fsWg11Oaf75W0nyWsSGWhXxBXR_RUCtPL-54qhAvB9t42gULEVq96_nD-1SJ3wcE6hwPuOdi0vDDOewGfJUTLY-dxFiwCUor_YQQKojlokoo1v-hIDtmxAhLn_myDZgTkDB-7aqeCc5Wg02RmoHGTIMLhY53NUwFCnnLvQlacF1dtkOmS6YGpJtZQDFI4IfBTLStgI-QTQN769hfgjDuaJWHWYyuDCbnq_WHGbjDHE66AO"
let allProducts = [];
let filteredProducts = [];
let currentPage = 1;
let pageSize = 10;
let editingProductId = null;
let existingImageUrlOnEdit = null;

const tableBody = document.getElementById('productsTableBody');
const searchInput = document.getElementById('searchInput');
const productModal = document.getElementById('productModal');
const productForm = document.getElementById('productForm');
const productModalTitle = document.getElementById('productModalTitle');
const productFormSubmitButton = document.getElementById('productFormSubmitButton');
const productIdInput = document.getElementById('productId');
const productNameInput = document.getElementById('productName');
const productCategoryIdInput = document.getElementById('productCategoryId');
const productPriceInput = document.getElementById('productPrice');
const productImageFileInput = document.getElementById('productImageFile'); // For file input
const productVarietiesInput = document.getElementById('productVarieties');
const productDescriptionInput = document.getElementById('productDescription');

const categoryFilterSelect = document.getElementById('categoryFilter');
const typeFilterSelect = document.getElementById('typeFilter');

const tableHeaders = document.querySelectorAll('.products-table th');

const fileDropArea = document.getElementById('fileDropArea');
const browseFileBtn = document.getElementById('browseFileBtn');
const fileNamePreview = document.getElementById('fileNamePreview');
const imagePreview = document.getElementById('imagePreview');
const fileDropDefaultContent = document.getElementById('fileDropDefaultContent');

document.addEventListener('DOMContentLoaded', () => {
    initializeProductPage();
    setupEventListeners();
});

function setupEventListeners() {
    if (fileDropArea && productImageFileInput && browseFileBtn && fileNamePreview) {
        fileDropArea.addEventListener('dragover', (event) => {
            event.preventDefault();
            fileDropArea.classList.add('dragover');
        });

        fileDropArea.addEventListener('dragleave', () => {
            fileDropArea.classList.remove('dragover');
        });

        fileDropArea.addEventListener('drop', (event) => {
            event.preventDefault();
            fileDropArea.classList.remove('dragover');
            const files = event.dataTransfer.files;
            if (files.length > 0) {
                productImageFileInput.files = files;
                updateFilePreview(files[0]);
            }
        });

        browseFileBtn.addEventListener('click', () => {
            productImageFileInput.click();
        });

        productImageFileInput.addEventListener('change', (event) => {
            const files = event.target.files;
            if (files.length > 0) {
                updateFilePreview(files[0]);
            }
        });
    }

        tableHeaders.forEach(header => {
        const sortIcon = header.querySelector('.fa-sort');
        if (sortIcon) {
            header.addEventListener('click', () => {
                const sortKey = header.getAttribute('data-sort-key');
                if (sortKey) {
                    toggleSort(sortKey, header);
                }
            });
        }
    });

    populateFilterDropdowns();
}

function populateFilterDropdowns() {
    const categories = ["Main", "Soup", "Dessert", "Snacks", "Drinks"];
    const types = ["Regular", "Medium", "Large"];

    if (categoryFilterSelect) {
        categoryFilterSelect.innerHTML = '<option value="">All Categories</option>';
        categories.forEach(cat => {
            const option = document.createElement('option');
            option.value = cat.toLowerCase();
            option.textContent = cat;
            categoryFilterSelect.appendChild(option);
        });
    }

    if (typeFilterSelect) {
        typeFilterSelect.innerHTML = '<option value="">All Types</option>';
        types.forEach(type => {
            const option = document.createElement('option');
            option.value = type.toLowerCase();
            option.textContent = type;
            typeFilterSelect.appendChild(option);
        });
    }
}

function updateFilePreview(file) {
    if (!file) return;
    fileNamePreview.textContent = file.name;
    if (file.type.startsWith('image/')) {
        const reader = new FileReader();
        reader.onload = (e) => {
            if (imagePreview && fileDropDefaultContent) {
                imagePreview.src = e.target.result;
                imagePreview.style.display = 'block';
                fileDropDefaultContent.style.display = 'none';
            }
        };
        reader.readAsDataURL(file);
    } else {
        if (imagePreview && fileDropDefaultContent) {
            imagePreview.style.display = 'none';
            fileDropDefaultContent.style.display = 'flex';
        }
    }
}

function clearFilePreview() {
    fileNamePreview.textContent = '';
    if (productImageFileInput) productImageFileInput.value = '';
    if (imagePreview && fileDropDefaultContent) {
        imagePreview.src = '#';
        imagePreview.style.display = 'none';
        fileDropDefaultContent.style.display = 'flex';
    }
}

async function initializeProductPage() {
    showLoading(true);
    await loadProductsFromFirestore();
    showLoading(false);
}

async function loadProductsFromFirestore() {
    try {
        showLoading(true);
        const q = query(menuCollectionRef, orderBy('name'));
        const snapshot = await getDocs(q);
        allProducts = snapshot.docs.map(doc => ({
            docId: doc.id,
            ...doc.data()
        }));
        applyFiltersAndRender();
    } catch (error) {
        console.error("Error loading products from Firestore: ", error);
        showError("Failed to load products.");
    } finally {
        showLoading(false);
    }
}

//Rendering and UI
function renderProducts() {
    if (!tableBody) return;
    tableBody.innerHTML = '';

    const startIndex = (currentPage - 1) * pageSize;
    const endIndex = startIndex + pageSize;
    const productsToShow = filteredProducts.slice(startIndex, endIndex);

    if (productsToShow.length === 0 && !document.querySelector('#productsTableBody .loading-row')) {
        tableBody.innerHTML = `<tr><td colspan="9" class="empty-state">No products found.</td></tr>`;
    } else {
        tableBody.innerHTML = productsToShow.map(product => `
            <tr class="product-row">
                <td><input type="checkbox" class="product-checkbox" data-id="${product.docId}"></td>
                <td><img src="${product.imageUrl || 'https://via.placeholder.com/40'}" alt="${product.name || 'Product Image'}" class="product-image"></td>
                <td>${product.id || 'N/A'}</td>
                <td>${product.name || 'N/A'}</td>
                <td>${product.categoryId || 'N/A'}</td>
                <td>₱${typeof product.price === 'number' ? product.price.toFixed(2) : '0.00'}</td>
                <td>${(Array.isArray(product.varieties) ? product.varieties.join(', ') : (product.varieties || 'N/A'))}</td>
                <td>${product.description || 'N/A'}</td>
                <td>
                    <button class="action-btn" onclick="openProductModal('${product.docId}')" title="Edit"><i class="fas fa-edit"></i></button>
                    <button class="action-btn" onclick="deleteProduct('${product.docId}')" title="Delete"><i class="fas fa-trash"></i></button>
                </td>
            </tr>
        `).join('');
    }
}

let currentSortKey = null;
let currentSortDirection = 'asc';

function toggleSort(sortKey, headerElement) {
    tableHeaders.forEach(header => {
        if (header !== headerElement) {
            const icon = header.querySelector('.fa-sort, .fa-sort-up, .fa-sort-down');
            if (icon) {
                icon.classList.remove('fa-sort-up', 'fa-sort-down');
                icon.classList.add('fa-sort');
            }
        }
    });

    const sortIcon = headerElement.querySelector('.fa-sort, .fa-sort-up, .fa-sort-down');

    if (currentSortKey === sortKey) {
        currentSortDirection = currentSortDirection === 'asc' ? 'desc' : 'asc';
    } else {
        currentSortKey = sortKey;
        currentSortDirection = 'asc';
    }

    if (sortIcon) {
        sortIcon.classList.remove('fa-sort', 'fa-sort-up', 'fa-sort-down');
        if (currentSortDirection === 'asc') {
            sortIcon.classList.add('fa-sort-up');
        } else {
            sortIcon.classList.add('fa-sort-down');
        }
    }

    applyFiltersAndRender();
}

window.clearFilters = function() {
    if (searchInput) searchInput.value = '';
    if (categoryFilterSelect) categoryFilterSelect.value = '';
    if (typeFilterSelect) typeFilterSelect.value = '';
    currentSortKey = null;
    currentSortDirection = 'asc';
    tableHeaders.forEach(header => {
        const icon = header.querySelector('.fa-sort, .fa-sort-up, .fa-sort-down');
        if (icon) {
            icon.classList.remove('fa-sort-up', 'fa-sort-down');
            icon.classList.add('fa-sort');
        }
    });

    applyFiltersAndRender();
};

function applyFiltersAndRender() {
    const searchTerm = searchInput ? searchInput.value.toLowerCase() : '';
    const selectedCategory = categoryFilterSelect ? categoryFilterSelect.value : '';
    const selectedType = typeFilterSelect ? typeFilterSelect.value : '';

    filteredProducts = allProducts.filter(product => {
        const nameMatch = product.name.toLowerCase().includes(searchTerm);
        const idMatch = product.id.toLowerCase().includes(searchTerm);
        const categoryMatch = selectedCategory ? product.categoryId.toLowerCase() === selectedCategory : true;
        
        let typeMatch = true;
        if (selectedType) {
            if (Array.isArray(product.varieties)) {
                typeMatch = product.varieties.some(v => v.toLowerCase() === selectedType);
            } else if (typeof product.varieties === 'string') {
                typeMatch = product.varieties.toLowerCase() === selectedType;
            }
        }

        return (nameMatch || idMatch) && categoryMatch && typeMatch;
    });

    //Sorting
    if (currentSortKey) {
        const categoryOrder = ["main", "soup", "dessert", "snacks", "drinks"];
        const typeOrder = ["regular", "medium", "large"];

        filteredProducts.sort((a, b) => {
            let valA, valB;

            if (currentSortKey === 'categoryId') {
                valA = categoryOrder.indexOf(a[currentSortKey]?.toLowerCase());
                valB = categoryOrder.indexOf(b[currentSortKey]?.toLowerCase());
                if (valA === -1) valA = categoryOrder.length;
                if (valB === -1) valB = categoryOrder.length;
            } else if (currentSortKey === 'varieties') {
                valA = typeOrder.indexOf(a[currentSortKey]?.toLowerCase());
                valB = typeOrder.indexOf(b[currentSortKey]?.toLowerCase());
                if (valA === -1) valA = typeOrder.length;
                if (valB === -1) valB = typeOrder.length;
            } else {
                valA = a[currentSortKey];
                valB = b[currentSortKey];
            }

            if (typeof valA === 'string' && typeof valB === 'string' && (currentSortKey !== 'categoryId' && currentSortKey !== 'varieties')) {
                valA = valA.toLowerCase();
                valB = valB.toLowerCase();
            }

            if (valA < valB) {
                return currentSortDirection === 'asc' ? -1 : 1;
            }
            if (valA > valB) {
                return currentSortDirection === 'asc' ? 1 : -1;
            }
            return 0;
        });
    }

    currentPage = 1;
    renderProducts();
    updateResultsInfo();
}

function updateResultsInfo() {
    const resultsInfo = document.getElementById('resultsInfo');
    if (resultsInfo) {
        const totalFiltered = filteredProducts.length;
        const start = totalFiltered > 0 ? (currentPage - 1) * pageSize + 1 : 0;
        const end = Math.min(currentPage * pageSize, totalFiltered);
        resultsInfo.textContent = `View Products: ${start}-${end} of ${totalFiltered}`;
    }
}

//Modal and Form Handling
window.openProductModal = function(productIdToEdit = null) {
    if (!productModal || !productForm || !productModalTitle || !productFormSubmitButton) {
        console.error("Modal or form elements not found!");
        return;
    }
    productForm.reset();
    editingProductId = productIdToEdit;
    existingImageUrlOnEdit = null;
    clearFilePreview();

    if (editingProductId) {
        productModalTitle.textContent = "Edit Product";
        const product = allProducts.find(p => p.docId === editingProductId);
        if (product) {
            if(productIdInput) productIdInput.value = product.id || '';
            if(productIdInput) productIdInput.readOnly = true;
            if(productNameInput) productNameInput.value = product.name || '';
            if(productCategoryIdInput) productCategoryIdInput.value = product.categoryId || '';
            if(productPriceInput) productPriceInput.value = product.price || '';
            existingImageUrlOnEdit = product.imageUrl || null;
            if(productVarietiesInput) productVarietiesInput.value = Array.isArray(product.varieties) ? product.varieties.join(',') : '';
            if(productDescriptionInput) productDescriptionInput.value = product.description || '';
            productFormSubmitButton.textContent = "Save Changes";
        } else {
            console.error("Product not found for editing");
            closeProductModal();
            return;
        }
    } else {
        productModalTitle.textContent = "Add New Product";
        if(productIdInput) productIdInput.readOnly = false;
        productFormSubmitButton.textContent = "Add Product";
    }
    productModal.classList.add('show');
}

window.closeProductModal = function() {
    if (productModal) {
        productModal.classList.remove('show');
        editingProductId = null;
        existingImageUrlOnEdit = null;
        if(productForm) productForm.reset();
        if(productIdInput) productIdInput.readOnly = false;
        if(productImageFileInput) productImageFileInput.value = null;
    }
}

window.handleProductFormSubmit = async function(event) {
    event.preventDefault();
    if (editingProductId) {
        await updateExistingProduct(editingProductId);
    } else {
        await addNewProductToFirestore();
    }
}

async function addNewProductToFirestore() {
    const id = productIdInput.value.trim();
    const name = productNameInput.value.trim();
    const categoryId = productCategoryIdInput.value;
    const price = parseFloat(productPriceInput.value);
    const imageFile = productImageFileInput.files[0];
    const varieties = productVarietiesInput.value;
    const description = productDescriptionInput.value.trim();

    if (!id || !name || !categoryId || isNaN(price) || !varieties) {
        alert("Product ID, Name, Category ID, and a valid Price are required.");
        return;
    }

    showLoading(true);
    let generatedImageUrl = null;
    try {
        if (imageFile) {
            generatedImageUrl = await uploadToDropboxAndGetUrl(imageFile, id);
            if (!generatedImageUrl) {
                alert("Image upload failed. Product will be saved without an image. You can edit it later to add an image.");
            }
        }

        const varietiesArray = varieties.split(',').map(v => v.trim()).filter(v => v);
        const productData = {
            id,
            name,
            categoryId,
            price,
            imageUrl: generatedImageUrl,
            varieties: varietiesArray,
            description,
            createdAt: serverTimestamp()
        };

        const productDocRef = doc(db, "menu", id);
        await setDoc(productDocRef, productData);
        console.log("Product added to Firestore with ID:", id);
        
        closeProductModal();
        await loadProductsFromFirestore();
        alert("Product added successfully!");

    } catch (error) {
        console.error("Error adding new product: ", error);
        alert(`Error adding new product: ${error.message}`);
    } finally {
        showLoading(false);
    }
}

async function updateExistingProduct(docId) {
    const name = productNameInput.value.trim();
    const categoryId = productCategoryIdInput.value;
    const price = parseFloat(productPriceInput.value);
    const imageFile = productImageFileInput.files[0];
    const varieties = productVarietiesInput.value;
    const description = productDescriptionInput.value.trim();

    if (!name || !categoryId || isNaN(price) || !varieties) {
        alert("Name, Category ID, and a valid Price are required.");
        return;
    }

    showLoading(true);
    let finalImageUrl = existingImageUrlOnEdit;

    try {
        if (imageFile) {
            const newImageUrl = await uploadToDropboxAndGetUrl(imageFile, docId);
            if (newImageUrl) {
                finalImageUrl = newImageUrl;
            } else {
                alert("New image upload failed. The existing image (if any) will be kept.");
            }
        }

        const varietiesArray = varieties.split(',').map(v => v.trim()).filter(v => v);
        const productData = {
            name,
            categoryId,
            price,
            varieties: varietiesArray,
            description,
            updatedAt: serverTimestamp()
        };

        const productDocRef = doc(db, "menu", docId);
        await updateDoc(productDocRef, productData);
        console.log("Product details updated in Firestore for ID:", docId);
        
        closeProductModal();
        await loadProductsFromFirestore();
        alert("Product details updated successfully!");

    } catch (error) {
        console.error("Error updating product: ", error);
        alert(`Error updating product: ${error.message}`);
    } finally {
        showLoading(false);
    }
}

//Dropbox Upload Function
async function uploadToDropboxAndGetUrl(file, productId) {
    if (!DROPBOX_ACCESS_TOKEN) {
        console.error("Dropbox Access Token is missing.");
        alert("Dropbox integration is not configured (missing token).");
        return null;
    }

    const UPLOAD_FILE_URL = 'https://content.dropboxapi.com/2/files/upload';
    const CREATE_SHARED_LINK_URL = 'https://api.dropboxapi.com/2/sharing/create_shared_link_with_settings';
    const LIST_SHARED_LINKS_URL = 'https://api.dropboxapi.com/2/sharing/list_shared_links';
    
    const uniqueFileName = `product_${productId}_${Date.now()}_${file.name.replace(/[^a-zA-Z0-9_.-]/g, '_')}`;
    const dropboxPath = `/Apps/HerenciaPOS/${uniqueFileName}`; 

    console.log(`Uploading ${file.name} to Dropbox path: ${dropboxPath}`);

    try {
        //Upload the File
        const uploadResponse = await fetch(UPLOAD_FILE_URL, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${DROPBOX_ACCESS_TOKEN}`,
                'Dropbox-API-Arg': JSON.stringify({
                    path: dropboxPath,
                    mode: 'add',
                    autorename: true,
                    mute: false
                }),
                'Content-Type': 'application/octet-stream'
            },
            body: file
        });

        if (!uploadResponse.ok) {
            const errorData = await uploadResponse.json();
            console.error('Dropbox upload error:', uploadResponse.status, errorData);
            throw new Error(`Dropbox upload failed: ${errorData.error_summary || uploadResponse.statusText}`);
        }
        const uploadedFileData = await uploadResponse.json();
        console.log('File uploaded to Dropbox:', uploadedFileData);
        const uploadedPath = uploadedFileData.path_lower;

        //Create/List Shared Link
        let sharedLinkData;
        try {
            const createLinkResponse = await fetch(CREATE_SHARED_LINK_URL, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${DROPBOX_ACCESS_TOKEN}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    path: uploadedPath,
                    settings: {
                        requested_visibility: 'public',
                        audience: 'public',
                        access: 'viewer'
                    }
                })
            });
            if (!createLinkResponse.ok) {
                const errorData = await createLinkResponse.json();
                if (errorData.error && errorData.error['.tag'] === 'shared_link_already_exists') {
                    console.log('Shared link already exists for path:', uploadedPath, 'Fetching existing links...');
                    const listLinksResponse = await fetch(LIST_SHARED_LINKS_URL, {
                        method: 'POST',
                        headers: {
                            'Authorization': `Bearer ${DROPBOX_ACCESS_TOKEN}`,
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({ path: uploadedPath })
                    });
                    if (!listLinksResponse.ok) {
                         const listErrorData = await listLinksResponse.json();
                        console.error('Dropbox list_shared_links error after already_exists:', listErrorData);
                        throw new Error(`Failed to list existing shared links: ${listErrorData.error_summary || listLinksResponse.statusText}`);
                    }
                    const existingLinksData = await listLinksResponse.json();
                    if (existingLinksData.links && existingLinksData.links.length > 0) {
                        sharedLinkData = existingLinksData.links[0];
                        console.log('Found existing shared link:', sharedLinkData);
                    } else {
                        console.error('Shared link already exists but could not be found via list_shared_links for path:', uploadedPath);
                        throw new Error('Shared link already exists but was not found.');
                    }
                } else {
                    console.error('Dropbox create shared link error:', errorData);
                    throw new Error(`Dropbox create shared link failed: ${errorData.error_summary || createLinkResponse.statusText}`);
                }
            } else {
                sharedLinkData = await createLinkResponse.json();
                console.log('Shared link created successfully:', sharedLinkData);
            }
        } catch (linkError) {
             console.error("Error during shared link creation/retrieval: ", linkError);
             throw linkError;
        }
        
        if (!sharedLinkData || !sharedLinkData.url) {
            console.error("Failed to obtain shared link data or URL.");
            throw new Error("Failed to get a valid shared link from Dropbox.");
        }

        let url = sharedLinkData.url;
        if (url.includes('?dl=0')) {
            url = url.replace('?dl=0', '?raw=1');
        } else if (!url.includes('?raw=1')) {
            url = url + (url.includes('?') ? '&raw=1' : '?raw=1');
        }
        if (url.startsWith('www.dropbox.com')) {
            url = url.replace('www.dropbox.com', 'dl.dropboxusercontent.com');
        }
        if (url.startsWith('http://')) {
             url = 'https://' + url.substring(7);
        } else if (!url.startsWith('https://')) {
             url = 'https://' + url;
        }

        console.log('Direct Dropbox URL:', url);
        return url;

    } catch (error) {
        console.error("Error in overall Dropbox operation: ", error);
        alert(`Dropbox operation failed: ${error.message}. Check console for details.`);
        return null;
    }
}

//Placeholder Functions
window.filterProducts = applyFiltersAndRender;

window.deleteProduct = async function(docId) {
    if (!confirm(`Are you sure you want to delete product ${docId}?`)) return;
    showLoading(true);
    try {
        await deleteDoc(doc(db, "menu", docId));
        alert("Product deleted successfully from Firestore.");
        loadProductsFromFirestore();
    } catch (error) {
        console.error("Error deleting product: ", error);
        alert(`Error deleting product: ${error.message}`);
    } finally {
        showLoading(false);
    }
};

window.exportProductsCSV = function() {
    alert("Export CSV function not implemented yet.");
};

window.toggleAllProducts = function(checkbox) {
    const checkboxes = document.querySelectorAll('#productsTableBody .product-checkbox');
    checkboxes.forEach(cb => cb.checked = checkbox.checked);
};

//UI Helper Functions
function showLoading(isLoading) {
    const tableBody = document.getElementById('productsTableBody');
    if (!tableBody) return;
    const loadingRowClass = 'loading-row';
    let loadingRow = tableBody.querySelector('.' + loadingRowClass);

    if (isLoading) {
        if (!loadingRow) {
            loadingRow = document.createElement('tr');
            loadingRow.className = loadingRowClass;
            loadingRow.innerHTML = `<td colspan="9" class="loading"><i class="fas fa-spinner fa-spin"></i> Loading...</td>`;
            if (tableBody.firstChild) {
                tableBody.insertBefore(loadingRow, tableBody.firstChild);
            } else {
                tableBody.innerHTML = loadingRow.outerHTML;
            }
        }
    } else {
        if (loadingRow) {
            loadingRow.remove();
        }
    }
}

function showError(message) {
    const tableBody = document.getElementById('productsTableBody');
    if (!tableBody) return;
    tableBody.innerHTML = `<tr><td colspan="9" class="empty-state"><i class="fas fa-exclamation-triangle"></i> ${message}</td></tr>`;
}

// Sidebar Toggle
window.toggleSidebar = function() {
    const sidebar = document.getElementById('sidebar');
    if (sidebar) {
        sidebar.classList.toggle('mobile-visible');
    }
};
document.addEventListener('click', function(event) {
    const sidebar = document.getElementById('sidebar');
    const mobileMenuBtn = document.querySelector('.mobile-menu-btn'); 
    if (window.innerWidth <= 768 && sidebar && mobileMenuBtn && sidebar.classList.contains('mobile-visible')) {
        if (!sidebar.contains(event.target) && !mobileMenuBtn.contains(event.target)) {
            sidebar.classList.remove('mobile-visible');
        }
    }
});
window.addEventListener('resize', function() {
    if (window.innerWidth > 768) {
        const sidebar = document.getElementById('sidebar');
        if (sidebar && sidebar.classList.contains('mobile-visible')) { 
            sidebar.classList.remove('mobile-visible');
        }
    }
});