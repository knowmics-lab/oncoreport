'use strict';

function makeSearchable (inputSelector, tableSelector) {
  const searchInput = document.querySelector(inputSelector);
  const searchTable = document.querySelector(tableSelector);
  const searchTableBody = searchTable ? searchTable.querySelector('tbody') : null;

  if (searchInput && searchTableBody) {
    const debouncedSearch = debounce((value) => {
      const searchValue = value.trim().toUpperCase();
      const rows = [...searchTableBody.querySelectorAll('tr')];
      rows.forEach((r) => r.classList.remove('d-none'));
      if (searchValue !== '') {
        rows.filter((r) =>
          [...r.querySelectorAll('td')].every(
            (td) => !td.textContent.toUpperCase().includes(searchValue)),
        ).forEach((r) => r.classList.add('d-none'));
      }
    });
    searchInput.addEventListener('input', (e) => debouncedSearch(e.target.value));
  }
}

function debounce (cb, delay = 200) {
  let timeout;

  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => {
      cb(...args);
    }, delay);
  };
}

makeSearchable('[data-search-input]', '[data-search-table-container] > table.table');
makeSearchable('[data-search-input-clinical]', '[data-search-table-container-clinical] > table.table');
makeSearchable('[data-search-input-others]', '[data-search-table-container-others] > table.table');