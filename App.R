
pacman::p_load(shiny, leaflet, sf, dplyr, shinyjs, rclipboard, rmapshaper, googlesheets4, base64enc)


# ─── GOOGLE SHEETS CONFIG ─────────────────────────────────────────────────────
SHEET_ID      <- "1l8SWu-LqcCFq6j_ypLk6LYu-kI1mHFv3xmwk4fF45ik"
SHEET_NAME    <- "session_logs"
LOGGING_ACTIVE <- FALSE   # set to TRUE once auth succeeds below


local({
  
  result <- tryCatch({
    
    sa <- list(
      type = "service_account",
      project_id= "humphrey-universal",
      private_key_id= "8db607c8db4f7e85a3e35c110dfa24d7a23cecad",
      private_key= "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQDDWtHyJNyYgx45\n8wPwKRLgDaNrT+L0U+o2bIQfasUhb8dKcRpaGS7oRF0zOpxttSGcKLZFoGxGVFKn\nsP2uc46aFz88MW4qrBupkJ+E0AfW8d/5oKpbGGpjlfvrwJz75GNDVQVRd/Qaom4H\nC3MrfhmdK6oTpOlWO9EiUrMYP1VFNFNzHEhvtR67kfBozZYJLGSsJy8CpIca6DDP\nkV4qrjOKwDNX02wE/cvOR2GJKB4p+bFJpirg7HK9Esmh1Afdz4lgM0/ugTApjbtm\nJ16VGswEm+55pTMOeynFZjR4cAWW54nLBQBqk5aV93q5kEhbLb4Np7x8y62ZLdot\n6gzSPydPAgMBAAECggEAExyyh4RwXyy3a1H0I63RCUHW/Wuzt4BHh2A3I4pi6Nzd\nBtJpPUFTeSkfDnZV0YHesj66vmBt11+ZNTYNS4ubUEX6oMfxOumFofbiibAp5C8x\nC2SwO034h++ngC64Ql3bZuii0Y/xE3NVXQkTZmuQKUlD+ryv5gjfcq0xP6u1NZo3\nfWF3KEPBp75J7/H8Moap9PjZFIrMhXTyS+I1gGtq5bhtS45EJvyBHp7USAv+AoxX\nT3pCNBk9jEXwVsPtbMVVp1tsKLmr5NFcF1LNlHcx8Hf06LrRD+w5UqDKIoamvwWK\ntHQATaRHueGtjCzK1UhmqSYnAkgRiIjk4yXQs8E4MQKBgQDmEhDUHg/VoX5w+Fjy\nzJqOrDyiCD/26Y/LbI7htueP93ZPNr7Ovu03uZ52RwYqp25aq3CU+SiMLajeIN+N\nIg/o0EARzW9X+bj3brEdNd2duk4NbcTA5Pts5/Wo1OCrpyllvDNDddkWttk0YEo+\njLgIbdci2t5iAFewgXY1xY0N1wKBgQDZXySxicKYZ2rbpgOw8BaFeyOvOFaL2AJq\nfayZwqYSg6adZGbqfwPB8FP/achg/tLd8EbmbJyqkauP/TKm3XGDOmV6/7y8IAXr\nZpjPP9NDrZSrE8sUczTdSrPfSYGJ9/uc8cOWRHdrnztdVuCwfH5BkuYxxx9pTi6m\nuVj5mpLTSQKBgQDPwe6abc8kviG9CDbigmrrfZN/Sm3gnUcxjoV0REPVWMTogWpK\nrlTuplr3OenSqMFZdUlD7b903mKIvCzDeMffF/dTXC04x5QFNFsSIqtOnIeRTteG\nzQBSdyD6ZcnAmEIk0Y+FUq1H+rQnvPAujco+KlpE6lo5K1AEXtQNeKiInwKBgQCR\nnPi5ra0b5vtgVJ/YYZzUoh7PfBAN8g/8Ql/jSM9zS5nLibyfjaJ4woOib7x5rXqY\njiMQrOVuJdMly9moimNGI1JjyPknlNQiU0I+Y2UkyxzyVXoPIvXg3/AKvfT29ZYq\nFpKNESRmhe6Aong2Ac+aIcvuwJM8OdFqgnMmEfQVcQKBgQC8/dZM9MBQIACtKPXM\nl/tX7TbUboaL1QYFDxOh7haid89gVZyWUTk3eXdBj4bGjev06G3F1+NZwVZtvso8\njdO9zWSQO2IxUsAEMdMzdODfMfKzVZjkVLH/+xYoCg8hZWmq9IKIZXWfUoqJiBy2\nnfdn4+Up7yIbCZMp2lGpRyqzyQ==\n-----END PRIVATE KEY-----\n",
      client_email= "uai-validator-logs@humphrey-universal.iam.gserviceaccount.com",
      client_id= "102151939837823842037",
      auth_uri= "https://accounts.google.com/o/oauth2/auth",
      token_uri= "https://oauth2.googleapis.com/token",
      auth_provider_x509_cert_url= "https://www.googleapis.com/oauth2/v1/certs",
      client_x509_cert_url= "https://www.googleapis.com/robot/v1/metadata/x509/uai-validator-logs%40humphrey-universal.iam.gserviceaccount.com",
      universe_domain= "googleapis.com"
    )
    
    # Convert list → JSON → temp file (required for older googlesheets4)
    tmp <- tempfile(fileext = ".json")
    
    writeLines(jsonlite::toJSON(sa, auto_unbox = TRUE, pretty = TRUE), tmp)
    
    gs4_auth(path = tmp)
    
    TRUE
    
  }, error = function(e) {
    
    message("[AUTH ERROR] Google Sheets authentication failed: ", e$message)
    FALSE
    
  })
  
  LOGGING_ACTIVE <<- result
})
# ──────────────────────────────────────────────────────────────────────────────


# --- JAVASCRIPT: AUTO-LOCK + DEVICE INFO ---
js_geoloc <- "
var watchId = null;

// Assign a persistent device ID (stored in localStorage) and send fingerprint.
// Must use 'shiny:connected' — not document.ready — because Shiny's WebSocket
// is not open yet at DOM-ready time, so setInputValue would silently fail.
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
  
  # ── Unique session ID ──────────────────────────────────────────────────────
  session_id <- paste0(format(Sys.time(), "%Y%m%d_%H%M%S"), "_", sample(100000:999999, 1))
  
  # ── Session-log accumulator ────────────────────────────────────────────────
  # All fields collected during the session; written as ONE row to the sheet.
  slog <- reactiveValues(
    session_start      = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    session_end        = NA_character_,
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
    written            = FALSE          # guard against double-writes
  )
  
  # ── Single-row writer (works from both reactive and onSessionEnded context) ─
  write_session_log <- function() {
    if (!LOGGING_ACTIVE)                  return(invisible(NULL))
    if (isTRUE(isolate(slog$written)))    return(invisible(NULL))
    tryCatch({
      safe_chr <- function(x) if (is.null(x) || length(x) == 0) NA_character_ else as.character(x[[1]])
      safe_dbl <- function(x) if (is.null(x) || length(x) == 0) NA_real_      else as.numeric(x[[1]])

      isolate({ slog$session_end <- format(Sys.time(), "%Y-%m-%d %H:%M:%S") })

      row <- data.frame(
        session_id         = safe_chr(session_id),
        session_start      = safe_chr(isolate(slog$session_start)),
        session_end        = safe_chr(isolate(slog$session_end)),
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
  # ──────────────────────────────────────────────────────────────────────────
  
  
  # --- 1. GPS LOGIC ---
  output$gps_controls <- renderUI({
    if (isTRUE(input$gps_active)) {
      actionButton("stop_gps", "Scanning... (Manual Lock)", class = "btn-warning", width = "100%")
    } else {
      actionButton("get_loc", "Start GPS Auto-Capture",
                   class = "btn-success btn-lg", icon = icon("play"), width = "100%")
    }
  })
  
  observeEvent(input$get_loc,  { shinyjs::js$start_watch(target_acc_limit) })
  observeEvent(input$stop_gps, { shinyjs::js$stop_watch() })
  
  # Capture device ID and info as soon as JS sends them
  observeEvent(input$device_id, {
    slog$device_id <- input$device_id
  }, once = TRUE)

  observeEvent(input$device_info, {
    slog$device_info <- input$device_info
  }, once = TRUE)
  
  # Capture GPS coords when locked; zoom map
  observeEvent(input$gps_active, {
    if (isFALSE(input$gps_active) && isTruthy(input$device_lat)) {
      slog$latitude  <- input$device_lat
      slog$longitude <- input$device_lng
      slog$accuracy_m <- input$device_acc
      leafletProxy("map") |>
        flyTo(lng = input$device_lng, lat = input$device_lat, zoom = 17)
    }
  })
  
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
  
  
  # --- 2. DATA LOADING ---
  observe({
    updateSelectInput(session, "country_file",
                      choices = list.files("gadm_data",    pattern = "\\.(shp|geojson)$"))
    updateSelectInput(session, "cluster_file",
                      choices = list.files("cluster_data", pattern = "\\.(shp|geojson)$"))
  })
  
  loaded_layers <- eventReactive(input$load_data, {
    req(input$country_file, input$cluster_file)
    slog$adm3_shapefile    <- input$country_file
    slog$cluster_shapefile <- input$cluster_file
    
    tryCatch({
      withProgress(message = "Parsing Shapefiles...", value = 0.5, {
        list(
          country = st_read(file.path("gadm_data",    input$country_file), quiet = TRUE) |> st_transform(4326),
          cluster = st_read(file.path("cluster_data", input$cluster_file), quiet = TRUE) |> st_transform(4326)
        )
      })
    }, error = function(e) {
      slog$error_message <- paste("Shapefile load error:", e$message)
      NULL
    })
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
  
  
  # --- 3. ANALYSIS ---
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
      pnt      <- st_as_sf(data.frame(x = input$device_lng, y = input$device_lat),
                           coords = c("x", "y"), crs = 4326)
      res_adm  <- st_join(pnt, loaded_layers()$country, join = st_intersects)
      res_clus <- st_join(pnt, loaded_layers()$cluster, join = st_intersects)
      
      find_neighbors <- function(point, layer, col_pattern) {
        current_idx    <- as.integer(st_intersects(point, layer))
        if (is.na(current_idx)) return("None")
        neighbors_idx  <- st_touches(layer[current_idx, ], layer)[[1]]
        col_name       <- grep(col_pattern, names(layer), ignore.case = TRUE, value = TRUE)[1]
        neighbor_names <- as.character(layer[[col_name]][neighbors_idx])
        if (length(neighbor_names) == 0) return("None found")
        paste(unique(neighbor_names), collapse = ", ")
      }
      
      cluster_df  <- loaded_layers()$cluster
      clus_col    <- grep("cluster|AEZ", names(cluster_df), ignore.case = TRUE, value = TRUE)[1]
      target_poly <- cluster_df[cluster_df[[clus_col]] == input$target_aez, ]
      dist_m      <- as.numeric(min(st_distance(pnt, target_poly)))
      
      get_v <- function(df, pat) {
        if (nrow(df) == 0) return("Outside Boundary")
        cn <- grep(pat, names(df), ignore.case = TRUE, value = TRUE)[1]
        if (is.na(cn)) return("Field Not Found")
        as.character(df[[cn]][1])
      }
      
      v_country  <- get_v(res_adm,  "NAME_0")
      v_province <- get_v(res_adm,  "NAME_1")
      v_district <- get_v(res_adm,  "NAME_2")
      v_ward     <- get_v(res_adm,  "NAME_3")
      v_det_aez  <- get_v(res_clus, "cluster|AEZ")
      v_dist     <- ifelse(dist_m < 1, "INSIDE TARGET", paste0(round(dist_m, 1), " m"))
      v_nb_aez   <- find_neighbors(pnt, loaded_layers()$cluster, "cluster|AEZ")
      v_nb_ward  <- find_neighbors(pnt, loaded_layers()$country,  "NAME_3")
      
      result_df <- data.frame(
        Metric = c(
          "Country (NAME_0)", "Province (NAME_1)", "District (NAME_2)", "Ward (NAME_3)",
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
      
      analysis_result(result_df)
      
      # Populate accumulator with full results then write the single log row
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
      
      write_session_log()
      
    }, error = function(e) {
      slog$error_message <- paste("Analysis error:", e$message)
      write_session_log()
      showNotification(paste("Analysis failed:", e$message), type = "error")
    })
  })
  
  output$analysis_table <- renderTable({
    req(analysis_result())
    analysis_result()
  }, striped = TRUE, bordered = TRUE)
  
  
  # --- 4. MAP ---
  output$map <- renderLeaflet({
    leaflet() |>
      addProviderTiles(providers$OpenStreetMap) |>
      setView(0, 0, 2)
  })
  
  observeEvent(input$device_lat, {
    col <- if (input$device_acc <= target_acc_limit) "green" else "orange"
    leafletProxy("map") |>
      clearGroup("pos") |>
      addCircles(input$device_lng, input$device_lat,
                 radius = input$device_acc, group = "pos", color = col) |>
      addMarkers(input$device_lng, input$device_lat, group = "pos")
  })
  
  observeEvent(loaded_layers(), {
    leafletProxy("map") |>
      clearGroup("shp") |>
      addPolygons(data = loaded_layers()$country,
                  group = "shp", color = "blue", weight = 1, fillOpacity = 0.05) |>
      addPolygons(data = loaded_layers()$cluster,
                  group = "shp", color = "red",  weight = 2, fillOpacity = 0.1)
  })
  
  # Fallback write on disconnect (catches sessions where analysis was never run)
  session$onSessionEnded(function() {
    write_session_log()
  })
}

shinyApp(ui, server)
