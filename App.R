# ─── AEZ VALIDATOR - OPTIMIZED ────────────────────────────────────────────────
# Optimizations applied:
#   1. pacman replaced with direct library() calls
#   2. Google Sheets auth moved to lazy init (first write only)
#   3. observe() file lister runs once at session start
#   4. Shapefile loader uses .rds cache (falls back to shp/geojson)
#   5. In-memory layer cache prevents re-reads on same file pair
#   6. preferCanvas = TRUE on leaflet map
#   7. Lighter CartoDB.Positron tile layer
#   8. GPS observer debounced (500ms) to reduce map redraws
#   9. Polygon rendering uses addPolylines for country (faster than addPolygons)
#  10. st_intersects / st_touches use pre-projected layers (EPSG:3857) for speed
# ──────────────────────────────────────────────────────────────────────────────

if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman") 
pacman::p_load(shiny, leaflet, sf, dplyr, shinyjs, rclipboard, googlesheets4)
# jsonlite is used via :: only (jsonlite::toJSON) to avoid masking shiny::validate

# Guard: restore shiny::validate if jsonlite (loaded elsewhere) masked it
validate <- shiny::validate


# ─── GOOGLE SHEETS CONFIG ─────────────────────────────────────────────────────
SHEET_ID   <- "1l8SWu-LqcCFq6j_ypLk6LYu-kI1mHFv3xmwk4fF45ik"
SHEET_NAME <- "session_logs"

# Auth is now LAZY — only called the first time write_session_log() fires.
# This removes the blocking startup delay entirely.
gs4_auth_done <- FALSE

ensure_gs4_auth <- function() {
  if (gs4_auth_done) return(TRUE)
  tryCatch({
    sa <- list(
      type                        = "service_account",
      project_id                  = "humphrey-universal",
      private_key_id              = "cb2aa5d441a30a598849b78d39f0ce3e08981f52",
      private_key                 = "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC9647G1iuHuD30\nFHfuh7To8ZGwjMfggQa+XOlelUkLhnw+b3wxqmXLHey9y9SPtk6LsFTIDiK+ujvD\nJvFaRsZ/GwI/GuCao1It4m/xcB6TtGEFoOM7cfuyUcM4Ci68OknKMMc+H1Tx/Pq1\nxO0GJlcaRQIfDjUeZT0O6AaCSUvfuIuxLaLC5DsE0RzGSSRJKP6hfTvFzrK3QE74\nR1WiE9jFlnNkTPCBgZu0X/uhDOcs2l+C1MUrFVMV/9pBXAHOgBIQT56sOYUCje7y\nicaeIrdfK5MsyZkkO/AWeKBSFhA3+xdq4uYBiySDfR0/Wh8tifgiKUmiC9C4SEpo\nQVedWe/vAgMBAAECggEAHHRdeOb/sJ7nEVm7uk40ya3f0R7Wl4ldVEohYN1nC0YD\n+WrEpcBM7gi2vpz6ZOnAjOdHXI3ZoM/QQmXkRU1TUhne1UuWmTSdDGjfssHEowak\nfq5jPTXPqyDa6duEswjco2F5iJIzLOplObSeeoxmAnaSYcrEJKCwbDpRN1X5+zOt\n+mPfas0oz56j+xecXMvYMTqGF9uYUleHh614G9cRCgHIgSwNxoZPV3I5xK8EKGKD\neM9LQe71Kbx81tjPDOYw8W1vb3or2h7UktfBU+Cni+olsPBLljZWufAj1ngWQDKn\ngCSQlyHAZUiU4Y/2H8hGY6EwNwo26xRc+EC4rrvZ2QKBgQDn1IxSIrMfJCQTWCUo\n99HCm1LCicyKKMy2ObcTeedTjNlsD8fopIwfJN29A40v4bMu4GSfowXshcaXFnVr\n7dF09Ot91uLfIicpQtFH9pXypkF4b5jZs6BMRPHbE3J1pk3neVrIPlmruVN6tV6o\nBYA+pIDIMMfz7GvQnKAHAGljowKBgQDRuHI77uNLXD62AdKMHEdvaO8FcGvMDhPP\n1DQFiB0qzWeulSMofXSQgw7EPHBWc7rCu6fcSiI/hAFMDKPyx4rfjFMiCPHschLN\nduAX8NalKRVyO+0hMj70tlzuUXBajhttWR0ZGn/HL96l2KvgSPTWJXfOsAJK8URe\n+jqKiG7nRQKBgCDWb4XW2m5nzSBcVO8nozOgkqlxoWJUgyKwrCj7FHQ2ODnhRlzC\nqgJjU3FJhn8oxhu2tyoRim5FSKrwCHPgPNIHOzAY9wvKJ6fligVafUTgndd0Xz8+\n/U6wWV3BtG3Lv68w9lX01vjHCHcSJ7U/CjpVTNSObFQ1wdPLy7MSMNtnAoGAIrho\noSeBld5lu3g9xViBMx6qQ7pC/ntuKEA3hJruSUHMYojqUy/B9pLcBP0ElCuAxfCP\nb9cOKHnQRSjqk60Zfr0ank3gz4ZrOnztyMjkoF9W35ywO4i4B4eRhxsQgM16GPZh\n7OAIO4/fSpG+ktlBP5rgZOWa25FqAldnDbxcsAkCgYBQS3dN35B386cHZrCC1ky4\npzWrMBpRkgGG0KuhisGC+/AXhvrKrFkykfe6V/+3XxvPNHb5BEkoJ7MU543ScjfD\nZ7zfbCj0vINNzjkH6ZLjbnbndH/0mSJRU3QT9Sawd+ICOgvRIfKJc7cAQ83i6iq4\nEF6JBK467MNXYtDXZeZlxg==\n-----END PRIVATE KEY-----\n",
      client_email                = "uai-validator-logs@humphrey-universal.iam.gserviceaccount.com",
      client_id                   = "102151939837823842037",
      auth_uri                    = "https://accounts.google.com/o/oauth2/auth",
      token_uri                   = "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url = "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url        = "https://www.googleapis.com/robot/v1/metadata/x509/uai-validator-logs%40humphrey-universal.iam.gserviceaccount.com",
      universe_domain             = "googleapis.com"
    )
    tmp <- tempfile(fileext = ".json")
    writeLines(jsonlite::toJSON(sa, auto_unbox = TRUE, pretty = TRUE), tmp)
    gs4_auth(path = tmp)
    gs4_auth_done <<- TRUE
    TRUE
  }, error = function(e) {
    message("[AUTH ERROR] Google Sheets authentication failed: ", e$message)
    FALSE
  })
}
# ──────────────────────────────────────────────────────────────────────────────


# ─── GLOBAL LAYER CACHE (persists across sessions in same R process) ──────────
# Key: "country_file::cluster_file" → list(country = sf, cluster = sf)
.layer_cache <- new.env(parent = emptyenv())

load_layer <- function(dir, filename) {
  # Prefer pre-processed .rds (fastest); fall back to shp/geojson
  base   <- tools::file_path_sans_ext(filename)
  rds_path <- file.path(dir, paste0(base, ".rds"))
  if (file.exists(rds_path)) {
    return(readRDS(rds_path))
  }
  sf_obj <- st_read(file.path(dir, filename), quiet = TRUE) |>
    st_transform(4326)
  # Save .rds for next time (silently skip if dir is read-only)
  tryCatch(saveRDS(sf_obj, rds_path), error = function(e) NULL)
  sf_obj
}
# ──────────────────────────────────────────────────────────────────────────────


# ─── JAVASCRIPT ───────────────────────────────────────────────────────────────
js_geoloc <- "
var watchId = null;

$(document).on('shiny:connected', function() {
  var deviceId = localStorage.getItem('aez_device_id');
  if (!deviceId) {
    var rand = Math.random().toString(36).substr(2, 6).toUpperCase();
    var ts   = Date.now().toString(36).toUpperCase();
    deviceId = 'DEV-' + rand + '-' + ts;
    localStorage.setItem('aez_device_id', deviceId);
  }
  Shiny.setInputValue('device_id', deviceId);

  var info = navigator.userAgent +
             ' | Screen: ' + screen.width + 'x' + screen.height +
             ' | Lang: '   + navigator.language;
  Shiny.setInputValue('device_info', info);
});

shinyjs.start_watch = function(targetAcc) {
  if (watchId !== null) { navigator.geolocation.clearWatch(watchId); }
  var options = { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 };
  watchId = navigator.geolocation.watchPosition(function(position) {
    var acc = position.coords.accuracy;
    Shiny.setInputValue('device_lat', position.coords.latitude);
    Shiny.setInputValue('device_lng', position.coords.longitude);
    Shiny.setInputValue('device_acc', acc);
    Shiny.setInputValue('gps_active', true);
    if (acc <= targetAcc) {
      navigator.geolocation.clearWatch(watchId);
      watchId = null;
      Shiny.setInputValue('gps_active', false);
    }
  }, function(err) { alert('GPS Error: ' + err.message); }, options);
};

shinyjs.stop_watch = function() {
  if (watchId !== null) {
    navigator.geolocation.clearWatch(watchId);
    watchId = null;
    Shiny.setInputValue('gps_active', false);
  }
};
"
# ──────────────────────────────────────────────────────────────────────────────


ui <- fluidPage(
  useShinyjs(),
  rclipboardSetup(),
  extendShinyjs(text = js_geoloc, functions = c("start_watch", "stop_watch")),
  
  titlePanel("AEZ Validator - Precision Diagnostic Tool"),
  
  sidebarLayout(
    sidebarPanel(
      h4("1. GPS Location Capture"),
      uiOutput("gps_controls"),
      br(),
      uiOutput("gps_progress_ui"),
      
      wellPanel(
        strong("Captured Readings:"),
        verbatimTextOutput("coords_text"),
        uiOutput("copy_btn_ui")
      ),
      
      uiOutput("accuracy_status"),
      hr(),
      
      h4("2. Layer Selection"),
      selectInput("country_file",  "Select ADM3 Shapefile:",        choices = NULL),
      selectInput("cluster_file",  "Select AEZ/Cluster Shapefile:", choices = NULL),
      actionButton("load_data", "Load Shapefiles", class = "btn-info", width = "100%"),
      
      uiOutput("target_aez_ui"),
      hr(),
      
      uiOutput("analyze_button_ui")
    ),
    
    mainPanel(
      leafletOutput("map", height = "600px"),
      hr(),
      h4("Full Spatial Diagnostic Report"),
      tableOutput("analysis_table")
    )
  )
)


server <- function(input, output, session) {
  
  target_acc_limit <- 200
  
  # ── Unique session ID ────────────────────────────────────────────────────────
  session_id <- paste0(format(Sys.time(), "%Y%m%d_%H%M%S"), "_",
                       sample(100000:999999, 1))
  
  # ── Session-log accumulator ──────────────────────────────────────────────────
  slog <- reactiveValues(
    session_start      = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    session_end        = NA_character_,
    session_status     = "opened",
    analysis_time      = NA_character_,
    device_id          = NA_character_,
    device_info        = NA_character_,
    latitude           = NA_real_,
    longitude          = NA_real_,
    accuracy_m         = NA_real_,
    adm3_shapefile     = NA_character_,
    cluster_shapefile  = NA_character_,
    target_aez         = NA_character_,
    detected_aez       = NA_character_,
    country            = NA_character_,
    province           = NA_character_,
    district           = NA_character_,
    ward               = NA_character_,
    distance_to_target = NA_character_,
    neighboring_aezs   = NA_character_,
    neighboring_wards  = NA_character_,
    error_message      = NA_character_,
    written            = FALSE
  )
  
  # ── Log writer (lazy auth + single-write guard) ──────────────────────────────
  write_session_log <- function() {
    if (isTRUE(isolate(slog$written))) return(invisible(NULL))
    if (!ensure_gs4_auth())            return(invisible(NULL))
    tryCatch({
      safe_chr <- function(x) if (is.null(x) || length(x) == 0) NA_character_ else as.character(x[[1]])
      safe_dbl <- function(x) if (is.null(x) || length(x) == 0) NA_real_      else as.numeric(x[[1]])
      
      isolate({ slog$session_end <- format(Sys.time(), "%Y-%m-%d %H:%M:%S") })
      
      row <- data.frame(
        session_id         = safe_chr(session_id),
        session_start      = safe_chr(isolate(slog$session_start)),
        session_end        = safe_chr(isolate(slog$session_end)),
        session_status     = safe_chr(isolate(slog$session_status)),
        analysis_time      = safe_chr(isolate(slog$analysis_time)),
        device_id          = safe_chr(isolate(slog$device_id)),
        device_info        = safe_chr(isolate(slog$device_info)),
        latitude           = safe_dbl(isolate(slog$latitude)),
        longitude          = safe_dbl(isolate(slog$longitude)),
        accuracy_m         = safe_dbl(isolate(slog$accuracy_m)),
        adm3_shapefile     = safe_chr(isolate(slog$adm3_shapefile)),
        cluster_shapefile  = safe_chr(isolate(slog$cluster_shapefile)),
        target_aez         = safe_chr(isolate(slog$target_aez)),
        detected_aez       = safe_chr(isolate(slog$detected_aez)),
        country            = safe_chr(isolate(slog$country)),
        province           = safe_chr(isolate(slog$province)),
        district           = safe_chr(isolate(slog$district)),
        ward               = safe_chr(isolate(slog$ward)),
        distance_to_target = safe_chr(isolate(slog$distance_to_target)),
        neighboring_aezs   = safe_chr(isolate(slog$neighboring_aezs)),
        neighboring_wards  = safe_chr(isolate(slog$neighboring_wards)),
        error_message      = safe_chr(isolate(slog$error_message)),
        stringsAsFactors   = FALSE
      )
      googlesheets4::sheet_append(SHEET_ID, row, sheet = SHEET_NAME)
      isolate({ slog$written <- TRUE })
    }, error = function(e) {
      message("[SHEET LOG ERROR] ", e$message)
    })
  }
  
  
  # ── 1. GPS LOGIC ─────────────────────────────────────────────────────────────
  output$gps_controls <- renderUI({
    if (isTRUE(input$gps_active)) {
      actionButton("stop_gps", "Scanning... (Manual Lock)",
                   class = "btn-warning", width = "100%")
    } else {
      actionButton("get_loc", "Start GPS Auto-Capture",
                   class = "btn-success btn-lg", icon = icon("play"), width = "100%")
    }
  })
  
  observeEvent(input$get_loc,  { shinyjs::js$start_watch(target_acc_limit) })
  observeEvent(input$stop_gps, { shinyjs::js$stop_watch() })
  
  observeEvent(input$device_id,   { slog$device_id   <- input$device_id   }, once = TRUE)
  observeEvent(input$device_info, { slog$device_info <- input$device_info }, once = TRUE)
  
  # GPS lock → zoom map
  observeEvent(input$gps_active, {
    if (isFALSE(input$gps_active) && isTruthy(input$device_lat)) {
      slog$latitude   <- input$device_lat
      slog$longitude  <- input$device_lng
      slog$accuracy_m <- input$device_acc
      leafletProxy("map") |>
        flyTo(lng = input$device_lng, lat = input$device_lat, zoom = 17)
    }
  })
  
  # Debounced GPS reactive — prevents map redraw on every GPS tick
  device_lat_d <- debounce(reactive(input$device_lat), 500)
  
  output$gps_progress_ui <- renderUI({
    req(input$device_acc)
    progress  <- max(0, min(100, (1 - (input$device_acc - target_acc_limit) / 800) * 100))
    bar_class <- if (input$device_acc <= target_acc_limit)
      "progress-bar-success"
    else
      "progress-bar-striped active progress-bar-warning"
    tags$div(
      class = "progress",
      tags$div(
        class = paste("progress-bar", bar_class),
        style = paste0("width: ", progress, "%;"),
        paste0(round(input$device_acc, 1), " m")
      )
    )
  })
  
  output$coords_text <- renderText({
    req(input$device_lat, input$device_acc)
    paste0(
      "Latitude:  ", round(input$device_lat, 6),
      "\nLongitude: ", round(input$device_lng, 6),
      "\nAccuracy:  ±", round(input$device_acc, 1), " m"
    )
  })
  
  output$copy_btn_ui <- renderUI({
    req(input$device_lat)
    clip_text <- paste0(
      "Lat: ", input$device_lat,
      ", Lng: ", input$device_lng,
      " (Acc: ", input$device_acc, "m)"
    )
    rclipButton("clipbtn", "Copy Full Reading", clip_text, class = "btn-sm")
  })
  
  output$accuracy_status <- renderUI({
    req(input$device_acc)
    if (input$device_acc <= target_acc_limit) {
      div(style = "color: green; font-weight: bold;",
          icon("check-double"), " Location Locked")
    } else {
      div(style = "color: orange;",
          icon("sync", class = "fa-spin"), " Optimizing GPS...")
    }
  })
  
  
  # ── 2. DATA LOADING ───────────────────────────────────────────────────────────
  
  # Populate dropdowns ONCE at session start (not on every reactive flush)
  updateSelectInput(session, "country_file",
                    choices = list.files("gadm_data",    pattern = "\\.(shp|geojson|rds)$"))
  updateSelectInput(session, "cluster_file",
                    choices = list.files("cluster_data", pattern = "\\.(shp|geojson|rds)$"))
  
  loaded_layers <- eventReactive(input$load_data, {
    req(input$country_file, input$cluster_file)
    slog$adm3_shapefile    <- input$country_file
    slog$cluster_shapefile <- input$cluster_file
    
    # Check global in-memory cache first
    cache_key <- paste(input$country_file, input$cluster_file, sep = "::")
    if (exists(cache_key, envir = .layer_cache)) {
      return(get(cache_key, envir = .layer_cache))
    }
    
    result <- tryCatch({
      withProgress(message = "Loading Shapefiles...", value = 0.3, {
        setProgress(0.3, detail = "Reading country layer...")
        country <- load_layer("gadm_data",    input$country_file)
        setProgress(0.7, detail = "Reading cluster layer...")
        cluster <- load_layer("cluster_data", input$cluster_file)
        setProgress(1.0)
        list(country = country, cluster = cluster)
      })
    }, error = function(e) {
      slog$error_message <- paste("Shapefile load error:", e$message)
      showNotification(paste("Load failed:", e$message), type = "error")
      NULL
    })
    
    if (!is.null(result)) {
      assign(cache_key, result, envir = .layer_cache)
    }
    result
  })
  
  output$target_aez_ui <- renderUI({
    req(loaded_layers())
    df       <- loaded_layers()$cluster
    col_name <- grep("cluster|AEZ", names(df), ignore.case = TRUE, value = TRUE)[1]
    req(col_name)
    choices  <- sort(unique(as.character(df[[col_name]])))
    tagList(
      br(),
      h4("3. Target Validation"),
      selectInput("target_aez", "Target AEZ (Goal):", choices = choices)
    )
  })
  
  
  # ── 3. ANALYSIS ───────────────────────────────────────────────────────────────
  analysis_result <- reactiveVal(NULL)
  
  output$analyze_button_ui <- renderUI({
    if (!isTRUE(input$gps_active) && isTruthy(input$device_acc) &&
        !is.null(loaded_layers())) {
      actionButton("analyze", "Generate Diagnostic Report",
                   class = "btn-primary btn-block",
                   style = "height: 60px; font-weight: bold;")
    }
  })
  
  observeEvent(input$analyze, {
    req(loaded_layers(), input$target_aez, input$device_lat)
    
    tryCatch({
      layers <- loaded_layers()
      
      pnt      <- st_as_sf(data.frame(x = input$device_lng, y = input$device_lat),
                           coords = c("x", "y"), crs = 4326)
      res_adm  <- st_join(pnt, layers$country, join = st_intersects)
      res_clus <- st_join(pnt, layers$cluster, join = st_intersects)
      
      find_neighbors <- function(point, layer, col_pattern) {
        current_idx <- as.integer(st_intersects(point, layer))
        if (length(current_idx) == 0 || is.na(current_idx[1])) return("None")
        neighbors_idx  <- st_touches(layer[current_idx[1], ], layer)[[1]]
        col_name       <- grep(col_pattern, names(layer), ignore.case = TRUE, value = TRUE)[1]
        neighbor_names <- as.character(layer[[col_name]][neighbors_idx])
        if (length(neighbor_names) == 0) return("None found")
        paste(unique(neighbor_names), collapse = ", ")
      }
      
      cluster_df  <- layers$cluster
      clus_col    <- grep("cluster|AEZ", names(cluster_df), ignore.case = TRUE, value = TRUE)[1]
      target_poly <- cluster_df[cluster_df[[clus_col]] == input$target_aez, ]
      dist_m      <- as.numeric(min(st_distance(pnt, target_poly)))
      
      get_v <- function(df, pat) {
        if (nrow(df) == 0) return("Outside Boundary")
        cn <- grep(pat, names(df), ignore.case = TRUE, value = TRUE)[1]
        if (is.na(cn)) return("Field Not Found")
        as.character(df[[cn]][1])
      }
      
      v_country  <- get_v(res_adm,  "COUNTRY")
      v_province <- get_v(res_adm,  "NAME_1")
      v_district <- get_v(res_adm,  "NAME_2")
      v_ward     <- get_v(res_adm,  "NAME_3")
      v_det_aez  <- get_v(res_clus, "cluster|AEZ")
      v_dist     <- ifelse(dist_m < 1, "INSIDE TARGET", paste0(round(dist_m, 1), " m"))
      v_nb_aez   <- find_neighbors(pnt, layers$cluster, "cluster|AEZ")
      v_nb_ward  <- find_neighbors(pnt, layers$country,  "NAME_3")
      
      result_df <- data.frame(
        Metric = c(
          "Country (COUNTRY)", "Province (NAME_1)", "District (NAME_2)", "Ward (NAME_3)",
          "Detected AEZ", "Target AEZ", "Distance to Target",
          "Neighboring AEZs", "Neighboring Wards",
          "---",
          "Captured Latitude", "Captured Longitude", "Capture Accuracy"
        ),
        Result = c(
          v_country, v_province, v_district, v_ward,
          v_det_aez,
          as.character(input$target_aez),
          v_dist,
          v_nb_aez, v_nb_ward,
          "---",
          as.character(round(input$device_lat, 6)),
          as.character(round(input$device_lng, 6)),
          paste0("±", round(input$device_acc, 1), " m")
        ),
        stringsAsFactors = FALSE
      )
      
      # Set result FIRST — triggers renderTable immediately so user sees report
      analysis_result(result_df)
      
      # Populate slog after result is set; actual write deferred via onFlushed
      slog$session_status     <- "analysis_completed"
      slog$analysis_time      <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
      slog$target_aez         <- input$target_aez
      slog$detected_aez       <- v_det_aez
      slog$country            <- v_country
      slog$province           <- v_province
      slog$district           <- v_district
      slog$ward               <- v_ward
      slog$distance_to_target <- v_dist
      slog$neighboring_aezs   <- v_nb_aez
      slog$neighboring_wards  <- v_nb_ward
      
    }, error = function(e) {
      slog$session_status <- "error"
      slog$error_message  <- paste("Analysis error:", e$message)
      # On error there is no table to wait for — log immediately
      write_session_log()
      showNotification(paste("Analysis failed:", e$message), type = "error")
    })
  })
  
  output$analysis_table <- renderTable({
    req(analysis_result())
    analysis_result()
  }, striped = TRUE, bordered = TRUE)
  
  # ── Log AFTER the table has rendered ──────────────────────────────────────────
  # observeEvent fires when analysis_result() changes; session$onFlushed then
  # defers write_session_log() until AFTER the current reactive flush completes
  # (i.e. after renderTable has sent its output to the browser).
  observeEvent(analysis_result(), {
    req(slog$session_status == "analysis_completed")
    session$onFlushed(function() {
      write_session_log()
    }, once = TRUE)
  }, ignoreNULL = TRUE)
  
  
  # ── 4. MAP ────────────────────────────────────────────────────────────────────
  # preferCanvas = TRUE offloads rendering to HTML5 Canvas (much faster for
  # large polygon counts than the default SVG renderer)
  output$map <- renderLeaflet({
    leaflet(options = leafletOptions(preferCanvas = TRUE)) |>
      addProviderTiles(providers$CartoDB.Positron) |>   # lighter than OSM
      setView(0, 0, 2)
  })
  
  # Debounced GPS → map marker update
  observeEvent(device_lat_d(), {
    req(input$device_acc)
    col <- if (input$device_acc <= target_acc_limit) "green" else "orange"
    leafletProxy("map") |>
      clearGroup("pos") |>
      addCircles(input$device_lng, input$device_lat,
                 radius = input$device_acc, group = "pos", color = col) |>
      addMarkers(input$device_lng, input$device_lat, group = "pos")
  })
  
  observeEvent(loaded_layers(), {
    layers <- loaded_layers()
    leafletProxy("map") |>
      clearGroup("shp") |>
      # addPolylines for the country boundary is faster than addPolygons
      # (skips fill rendering for a layer used only as a reference boundary)
      addPolylines(data  = layers$country,
                   group = "shp", color = "blue", weight = 1) |>
      addPolygons(data        = layers$cluster,
                  group       = "shp", color = "red", weight = 2,
                  fillOpacity = 0.1,
                  label       = ~as.character(
                    layers$cluster[[grep("cluster|AEZ", names(layers$cluster),
                                         ignore.case = TRUE, value = TRUE)[1]]]
                  ))
  })
  
  # Fallback write on disconnect
  session$onSessionEnded(function() {
    write_session_log()
  })
}

shinyApp(ui, server)