import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { encode } from "https://deno.land/std@0.168.0/encoding/base64.ts";

console.log("Function loading...");

// --- Polyfills for pdfmake ---
if (!globalThis.window) {
  (globalThis as any).window = globalThis;
}
if (!globalThis.document) {
  (globalThis as any).document = {
    createElementNS: () => { return {}; },
    createElement: () => { 
      return { 
        getContext: () => ({
          measureText: () => ({ width: 10 }) 
        }) 
      }; 
    } 
  };
}
if (!globalThis.navigator) {
  (globalThis as any).navigator = { userAgent: "Deno" };
}

// Helper to load pdfmake dynamically
async function loadPdfMake() {
  console.log("Loading pdfmake modules...");
  try {
    const pdfMakeModule = await import("https://esm.sh/pdfmake@0.2.8/build/pdfmake.min.js");
    const pdfFontsModule = await import("https://esm.sh/pdfmake@0.2.8/build/vfs_fonts.js");
    
    const pdfMake = pdfMakeModule.default || pdfMakeModule;
    const pdfFonts = pdfFontsModule.default || pdfFontsModule;

    if (pdfFonts && pdfFonts.pdfMake && pdfFonts.pdfMake.vfs) {
      pdfMake.vfs = pdfFonts.pdfMake.vfs;
    } else if (pdfMake && pdfFonts) {
       (pdfMake as any).vfs = (pdfFonts as any).vfs;
    }
    console.log("pdfmake loaded successfully");
    return pdfMake;
  } catch (e) {
    console.error("Error loading pdfmake:", e);
    throw e;
  }
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Функция для загрузки шрифта по URL и конвертации в Base64
async function loadFontToBase64(url: string): Promise<string> {
  console.log(`Loading font from ${url}...`);
  try {
    const response = await fetch(url);
    if (!response.ok) throw new Error(`Failed to load font: ${response.statusText}`);
    const arrayBuffer = await response.arrayBuffer();
    return encode(new Uint8Array(arrayBuffer));
  } catch (e) {
    console.error(`Error loading font ${url}:`, e);
    throw e;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    console.log("Request received");
    
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    let body;
    try {
      body = await req.json();
    } catch (e) {
      console.error("Error parsing JSON body:", e);
      throw new Error("Invalid JSON body");
    }

    const { 
      objectId, 
      dateFrom, 
      dateTo,
      systemFilters,
      sectionFilters,
      floorFilters,
      searchQuery
    } = body;

    console.log(`Parameters: objectId=${objectId}, period=${dateFrom}-${dateTo}`);

    if (!objectId || !dateFrom || !dateTo) {
      throw new Error("Не указаны обязательные параметры");
    }

    const pdfMake = await loadPdfMake();

    // --- 1. Сбор данных ---
    console.log("Fetching data from Supabase...");

    // 1.1 Инфо об объекте
    const { data: objectData, error: objectError } = await supabase
      .from("objects")
      .select("name, address")
      .eq("id", objectId)
      .single();

    if (objectError) {
      console.error("Error fetching object:", objectError);
      throw objectError;
    }

    // 1.2 Получение работ (с пагинацией) + Лимиты и История
    // Добавляем новые поля в запрос к contracts и estimates
    let query = supabase
      .from("work_items")
      .select(`
        system,
        section,
        floor,
        name,
        unit,
        quantity,
        estimates (
          id,
          number,
          quantity, 
          contracts (
            id,
            number,
            date,
            contractor_legal_name,
            contractor_position,
            contractor_signer,
            customer_legal_name,
            customer_position,
            customer_signer
          )
        ),
        works!inner (
          object_id,
          date
        )
      `)
      .eq("works.object_id", objectId)
      .gte("works.date", dateFrom)
      .lte("works.date", dateTo);

    if (systemFilters?.length) query = query.in('system', systemFilters);
    if (sectionFilters?.length) query = query.in('section', sectionFilters);
    if (floorFilters?.length) query = query.in('floor', floorFilters);
    if (searchQuery?.trim()) query = query.ilike('name', `%${searchQuery.trim()}%`);

    const allItems: any[] = [];
    let offset = 0;
    const limit = 1000;
    let hasMore = true;

    while (hasMore) {
      console.log(`Fetching items offset=${offset}...`);
      const { data, error } = await query.range(offset, offset + limit - 1);
      if (error) {
        console.error("Error fetching items:", error);
        throw error;
      }

      if (data && data.length > 0) {
        allItems.push(...data);
        if (data.length < limit) hasMore = false;
      } else {
        hasMore = false;
      }
      offset += limit;
    }
    console.log(`Fetched ${allItems.length} items total.`);

    // 1.3 Fetch historical usage (volumes BEFORE this period)
    console.log("Fetching historical usage...");
    // We need to sum quantities for the same estimate_ids, but before dateFrom
    // To do this efficiently, we'll first get the list of unique estimate IDs involved
    const estimateIds = [...new Set(allItems.map(i => i.estimates?.id).filter(id => !!id))];
    
    const historicalUsageMap = new Map(); // estimate_id -> total_used_before
    
    if (estimateIds.length > 0) {
        // We'll fetch in chunks to avoid URL length limits
        const chunkSize = 100;
        for (let i = 0; i < estimateIds.length; i += chunkSize) {
             const chunk = estimateIds.slice(i, i + chunkSize);
             const { data: historyData, error: historyError } = await supabase
                .from("work_items")
                .select(`estimate_id, quantity, works!inner(date)`)
                .in("estimate_id", chunk)
                .lt("works.date", dateFrom); // Strictly less than start date
             
             if (historyError) {
                 console.error("Error fetching history:", historyError);
                 // Non-critical, assume 0 usage if fails? Or throw? Better throw to ensure data integrity.
                 throw historyError;
             }
             
             historyData?.forEach((hItem: any) => {
                 const eid = hItem.estimate_id;
                 const qty = Number(hItem.quantity) || 0;
                 historicalUsageMap.set(eid, (historicalUsageMap.get(eid) || 0) + qty);
             });
        }
    }


    const items = allItems;

    // 1.4 Группировка по договорам
    const contractsMap = new Map();

    if (items && items.length > 0) {
      items.forEach((item: any) => {
        const contract = item.estimates?.contracts;
        
        let contractKey = "no_contract";
        let contractLabel = "Без договора";
        let contractDateStr = "";
        let contractSignatories = null;

        if (contract) {
          contractKey = contract.id || `${contract.number}_${contract.date}`;
          const cDate = contract.date ? new Date(contract.date).toLocaleDateString("ru-RU") : "";
          contractLabel = `№ ${contract.number || "б/н"} от ${cDate}`;
          contractDateStr = contract.date || "";
          
          contractSignatories = {
            contractor: {
              name: contract.contractor_legal_name || '—',
              position: contract.contractor_position || 'Должность',
              signer: contract.contractor_signer || '/___________/'
            },
            customer: {
              name: contract.customer_legal_name || '—',
              position: contract.customer_position || 'Должность',
              signer: contract.customer_signer || '/___________/'
            }
          };
        }

        if (!contractsMap.has(contractKey)) {
          contractsMap.set(contractKey, {
            label: contractLabel,
            signatories: contractSignatories,
            items: []
          });
        }
        contractsMap.get(contractKey).items.push(item);
      });
    } else {
      contractsMap.set("empty", { label: "—", items: [] });
    }

    // --- 2. Подготовка шрифтов ---
    console.log("Loading fonts...");
    const fontUrls = {
      regular: "https://raw.githubusercontent.com/google/fonts/main/ofl/ptserif/PTSerif-Regular.ttf",
      bold: "https://raw.githubusercontent.com/google/fonts/main/ofl/ptserif/PTSerif-Bold.ttf"
    };

    let vfs = {};
    let fontConfig = {};

    try {
      const [fontRegularBase64, fontBoldBase64] = await Promise.all([
        loadFontToBase64(fontUrls.regular),
        loadFontToBase64(fontUrls.bold)
      ]);
      console.log("Fonts loaded successfully.");
      
      vfs = pdfMake.vfs || {};
      vfs["PTSerif-Regular.ttf"] = fontRegularBase64;
      vfs["PTSerif-Bold.ttf"] = fontBoldBase64;
      
      fontConfig = {
        PTSerif: {
          normal: 'PTSerif-Regular.ttf',
          bold: 'PTSerif-Bold.ttf',
          italics: 'PTSerif-Regular.ttf',
          bolditalics: 'PTSerif-Bold.ttf'
        }
      };
    } catch (e) {
      console.error("Failed to load custom fonts, falling back to default:", e);
      vfs = pdfMake.vfs || {};
      fontConfig = {
        Roboto: {
          normal: 'Roboto-Regular.ttf',
          bold: 'Roboto-Medium.ttf',
          italics: 'Roboto-Italic.ttf',
          bolditalics: 'Roboto-MediumItalic.ttf'
        }
      };
    }

    pdfMake.vfs = vfs;
    pdfMake.fonts = fontConfig;

    // --- 3. Генерация PDF (Multidoc) ---
    console.log("Generating PDF content...");

    const fontName = fontConfig['PTSerif'] ? 'PTSerif' : 'Roboto';
    const sortedContractKeys = Array.from(contractsMap.keys());
    const formatDate = (dateStr: string) => {
        try {
          const date = new Date(dateStr);
          return date.toLocaleDateString("ru-RU");
        } catch {
          return dateStr;
        }
      };
    const periodText = `${formatDate(dateFrom)} - ${formatDate(dateTo)}`;

    // Helper to generate PDF buffer
    const generatePdfBuffer = (docDefinition: any) => {
      const pdfDocGenerator = pdfMake.createPdf(docDefinition);
      return new Promise<Uint8Array>((resolve, reject) => {
        pdfDocGenerator.getBuffer((buffer: Uint8Array) => {
          resolve(buffer);
        });
      });
    };

    const pdfBuffers: Uint8Array[] = [];

    // Генерируем отдельный PDF для каждого договора
    for (const key of sortedContractKeys) {
        const contractGroup = contractsMap.get(key);
        const groupItems = contractGroup.items;
        const sigs = contractGroup.signatories || {
             contractor: { name: '—', position: 'Должность', signer: '/___________/' },
             customer: { name: '—', position: 'Должность', signer: '/___________/' }
        };

        const formatSigner = (signer: string) => {
            if (signer.startsWith('/')) return `____________________ ${signer}`;
            return `____________________ /${signer}/`;
        };

        // --- Data Aggregation Logic with Overrun Splitting ---
        
        // 1. Group raw items by unique Work Key (to handle multiple work_items for same task)
        // But we need to keep track of estimate_id to check limits.
        const groupedData = new Map(); // key -> { quantity, ...info, limit, usedBefore }
        
        groupItems.forEach((item: any) => {
            const lsrNumber = item.estimates?.number || "—";
            const estimateId = item.estimates?.id;
            const itemKey = `${item.system}_${item.name}_${item.unit}_${lsrNumber}`; // Simple key
            
            if (!groupedData.has(itemKey)) {
                groupedData.set(itemKey, {
                    itemKey: itemKey,
                    lsrNumber: lsrNumber,
                    section: item.system,
                    name: item.name,
                    unit: item.unit,
                    estimateId: estimateId,
                    limit: Number(item.estimates?.quantity) || 0, // Estimate limit
                    usedBefore: historicalUsageMap.get(estimateId) || 0, // Used before this period
                    currentTotal: 0,
                });
            }
            
            const qty = Number(item.quantity);
            if (!isNaN(qty)) groupedData.get(itemKey).currentTotal += qty;
        });

        // 2. Process limits and split into Normal and Overrun
        const normalRows: any[] = [];
        const overrunRows: any[] = [];

        groupedData.forEach((data) => {
            // Logic:
            // Limit = 100
            // UsedBefore = 80
            // Remaining = 20
            // CurrentTotal = 50
            // -> Normal: 20
            // -> Overrun: 30

            // If no limit (e.g. extra work without estimate link?), treat as overrun or normal? 
            // If estimate exists but limit is 0/null -> assume all overrun? Or unlimited?
            // Usually estimate quantity > 0.
            
            const limit = data.limit;
            const usedBefore = data.usedBefore;
            const remaining = Math.max(0, limit - usedBefore);
            const current = data.currentTotal;

            if (current <= 0) return; // Skip zero/negative

            if (data.estimateId && limit > 0) {
                if (current <= remaining) {
                    // All fits
                    normalRows.push({ ...data, displayQuantity: current });
                } else {
                    // Split
                    if (remaining > 0) {
                        normalRows.push({ ...data, displayQuantity: remaining });
                    }
                    const overrun = current - remaining;
                    overrunRows.push({ ...data, displayQuantity: overrun });
                }
            } else {
                // If no estimate or no limit defined, OR limit is 0, put everything in OVERRUN.
                // Assuming if limit is 0 or undefined, it means this work was not planned in the contract.
                overrunRows.push({ ...data, displayQuantity: current });
            }
        });

        // 3. Sort both lists
        const sortFn = (a: any, b: any) => {
            const sectionCompare = a.section.localeCompare(b.section);
            if (sectionCompare !== 0) return sectionCompare;
            const lsrCompare = String(a.lsrNumber).localeCompare(String(b.lsrNumber), 'ru', { numeric: true });
            if (lsrCompare !== 0) return lsrCompare;
            return a.name.localeCompare(b.name);
        };

        normalRows.sort(sortFn);
        overrunRows.sort(sortFn);

        // -- Build Table Body --
        const tableBody = [
            // Header
            [
            { text: '№ п/п', style: 'tableHeader' },
            { text: '№ по ЛСР', style: 'tableHeader' },
            { text: 'Раздел', style: 'tableHeader' },
            { text: 'Наименование работ', style: 'tableHeader' },
            { text: 'Ед. изм.', style: 'tableHeader' },
            { text: 'Кол-во', style: 'tableHeader' }
            ]
        ];

        let rowCounter = 1;

        // 1. Normal Rows
        if (normalRows.length > 0) {
            normalRows.forEach((row: any) => {
                tableBody.push([
                    { text: (rowCounter++).toString(), style: 'tableCell', alignment: 'center' },
                    { text: row.lsrNumber.toString(), style: 'tableCell', alignment: 'center' },
                    { text: row.section, style: 'tableCell', alignment: 'left' },
                    { text: row.name, style: 'tableCell', alignment: 'left' },
                    { text: row.unit, style: 'tableCell', alignment: 'center' },
                    { text: Number(row.displayQuantity.toFixed(3)).toString(), style: 'tableCell', alignment: 'right' }
                ]);
            });
        } else if (overrunRows.length === 0) {
             tableBody.push([
                { text: 'Нет данных', colSpan: 6, alignment: 'center', style: 'tableCell' }, {}, {}, {}, {}, {}
            ]);
        }

        // 2. Overrun Rows (Separator + Items)
        if (overrunRows.length > 0) {
            // Separator Row
            tableBody.push([
                { 
                    text: 'ПРЕВЫШЕНИЕ ОБЪЕМОВ И ДОПОЛНИТЕЛЬНЫЕ РАБОТЫ, ТРЕБУЮЩИЕ ДОП. СОГЛАШЕНИЯ', 
                    colSpan: 6, 
                    alignment: 'center', 
                    style: 'separatorRow',
                    fillColor: '#eeeeee'
                }, 
                {}, {}, {}, {}, {}
            ]);

            overrunRows.forEach((row: any) => {
                tableBody.push([
                    { text: (rowCounter++).toString(), style: 'tableCell', alignment: 'center' },
                    { text: row.lsrNumber.toString(), style: 'tableCell', alignment: 'center' },
                    { text: row.section, style: 'tableCell', alignment: 'left' },
                    { text: row.name, style: 'tableCell', alignment: 'left' },
                    { text: row.unit, style: 'tableCell', alignment: 'center' },
                    { text: Number(row.displayQuantity.toFixed(3)).toString(), style: 'tableCell', alignment: 'right' }
                ]);
            });
        }

        // Контент одного документа
        const content = [
             // Инфо-блок
            {
            columns: [
                { width: 'auto', text: 'Объект:', style: 'label' },
                { width: '*', text: objectData.name || '', style: 'value' }
            ],
            margin: [0, 0, 0, 5]
            },
            {
            columns: [
                { width: 'auto', text: 'Адрес:', style: 'label' },
                { width: '*', text: objectData.address || '—', style: 'value' }
            ],
            margin: [0, 0, 0, 5]
            },
            {
            columns: [
                { width: 'auto', text: 'Договор:', style: 'label' },
                { width: '*', text: contractGroup.label, style: 'value' }
            ],
            margin: [0, 0, 0, 5]
            },
            {
            columns: [
                { width: 'auto', text: 'Период:', style: 'label' },
                { width: '*', text: periodText, style: 'value' }
            ],
            margin: [0, 0, 0, 20]
            },

            { text: 'ВЕДОМОСТЬ ОБЪЁМОВ РАБОТ', style: 'header', alignment: 'center', margin: [0, 0, 0, 20] },
            
            // Таблица
            {
            table: {
                headerRows: 1, 
                widths: [37, 37, 37, '*', 37, 37], 
                body: tableBody
            },
            layout: {
                hLineWidth: (i: any) => 0.5,
                vLineWidth: (i: any) => 0.5,
                hLineColor: (i: any) => 'black',
                vLineColor: (i: any) => 'black',
                paddingLeft: (i: any) => 2,
                paddingRight: (i: any) => 2,
                paddingTop: (i: any) => 1, 
                paddingBottom: (i: any) => 1, 
            }
            }
        ];

        const docDefinition = {
            content: content,
            footer: function(currentPage: number, pageCount: number) {
              return {
                margin: [40, 10, 40, 40],
                stack: [
                  {
                    columns: [
                      // Слева: Подрядчик
                      {
                        width: '*',
                        stack: [
                          { text: 'Подготовил', fontSize: 8, bold: true, margin: [0, 0, 0, 5] },
                          { text: `Подрядчик: ${sigs.contractor.name}`, fontSize: 8, bold: true, margin: [0, 0, 0, 25] },
                          { text: `${sigs.contractor.position} ${formatSigner(sigs.contractor.signer)}`, fontSize: 8 }
                        ],
                        alignment: 'left'
                      },
                      // Справа: Заказчик
                      {
                        width: '*',
                        stack: [
                          { text: 'Согласовал', fontSize: 8, bold: true, margin: [0, 0, 0, 5] },
                          { text: `Заказчик: ${sigs.customer.name}`, fontSize: 8, bold: true, margin: [0, 0, 0, 25] },
                          { text: `${sigs.customer.position} ${formatSigner(sigs.customer.signer)}`, fontSize: 8 }
                        ],
                        alignment: 'right'
                      }
                    ]
                  },
                  // Номер страницы (локальный для договора)
                  {
                    text: `стр. ${currentPage} из ${pageCount}`,
                    fontSize: 6,
                    alignment: 'center',
                    margin: [0, 10, 0, 0]
                  }
                ]
              };
            },
            pageSize: 'A4',
            pageMargins: [40, 40, 40, 120],
            defaultStyle: {
              font: fontName,
              fontSize: 8
            },
            styles: {
                header: { fontSize: 10, bold: true },
                label: { fontSize: 8, bold: true, width: 80, margin: [0, 0, 10, 0] },
                value: { fontSize: 8, bold: false },
                tableHeader: { bold: true, fontSize: 8, alignment: 'center' },
                tableCell: { fontSize: 8 },
                separatorRow: { fontSize: 8, bold: true, alignment: 'center' }
            }
        };

        const buffer = await generatePdfBuffer(docDefinition);
        pdfBuffers.push(buffer);
    }

    let finalPdfBuffer: Uint8Array;

    if (pdfBuffers.length === 0) {
        throw new Error("No data generated");
    } else if (pdfBuffers.length === 1) {
        finalPdfBuffer = pdfBuffers[0];
    } else {
        console.log("Merging multiple PDFs...");
        const { PDFDocument } = await import("https://esm.sh/pdf-lib@1.17.1");
        const mergedPdf = await PDFDocument.create();
        
        for (const buffer of pdfBuffers) {
            const doc = await PDFDocument.load(buffer);
            const copiedPages = await mergedPdf.copyPages(doc, doc.getPageIndices());
            copiedPages.forEach((page) => mergedPdf.addPage(page));
        }
        finalPdfBuffer = await mergedPdf.save();
    }
    
    console.log("PDF generated. Encoding...");
    const base64Pdf = encode(finalPdfBuffer);
    console.log("Done.");

    return new Response(JSON.stringify({ 
      file: base64Pdf,
      filename: `vor_${objectId}.pdf`
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("Global error handler:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
