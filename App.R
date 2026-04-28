
pacman::p_load(shiny, leaflet, sf, dplyr, shinyjs, rclipboard, rmapshaper)



# --- JAVASCRIPT: AUTO-LOCK LOGIC ---
js_geoloc <- "
var watchId = null;
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
      # SECTION 1: GPS
      h4("1. GPS Location Capture"),
      uiOutput("gps_controls"),
      br(),
      uiOutput("gps_progress_ui"),
      
      # UPDATED: Clearer output for captured readings
      wellPanel(
        strong("Captured Readings:"),
        verbatimTextOutput("coords_text"),
        uiOutput("copy_btn_ui")
      ),
      
      uiOutput("accuracy_status"),
      hr(),
      
      # SECTION 2: LAYERS
      h4("2. Layer Selection"),
      selectInput("country_file", "Select ADM3 Shapefile:", choices = NULL),
      selectInput("cluster_file", "Select AEZ/Cluster Shapefile:", choices = NULL),
      actionButton("load_data", "Load Shapefiles", class = "btn-info", width = "100%"),
      
      uiOutput("target_aez_ui"),
      hr(),
      
      # SECTION 3: ANALYSIS
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
  
  # --- 1. GPS LOGIC ---
  output$gps_controls <- renderUI({
    if (isTRUE(input$gps_active)) {
      actionButton("stop_gps", "Scanning... (Manual Lock)", class = "btn-warning", width = "100%")
    } else {
      actionButton("get_loc", "Start GPS Auto-Capture", class = "btn-success btn-lg", icon = icon("play"), width = "100%")
    }
  })
  
  observeEvent(input$get_loc, { shinyjs::js$start_watch(target_acc_limit) })
  observeEvent(input$stop_gps, { shinyjs::js$stop_watch() })
  
  # Zoom on Lock
  observeEvent(input$gps_active, {
    if (isFALSE(input$gps_active) && isTruthy(input$device_lat)) {
      leafletProxy("map") %>% flyTo(lng = input$device_lng, lat = input$device_lat, zoom = 17)
    }
  })
  
  output$gps_progress_ui <- renderUI({
    req(input$device_acc)
    progress <- max(0, min(100, (1 - (input$device_acc - target_acc_limit) / 800) * 100))
    bar_class <- if(input$device_acc <= target_acc_limit) "progress-bar-success" else "progress-bar-striped active progress-bar-warning"
    tags$div(class = "progress", tags$div(class = paste("progress-bar", bar_class), style = paste0("width: ", progress, "%;"), paste0(round(input$device_acc, 1), " m")))
  })
  
  # UPDATED: Sidebar now shows all 3 key readings clearly
  output$coords_text <- renderText({ 
    req(input$device_lat, input$device_acc)
    paste0("Latitude:  ", round(input$device_lat, 6), 
           "\nLongitude: ", round(input$device_lng, 6), 
           "\nAccuracy:  ±", round(input$device_acc, 1), " m") 
  })
  
  output$copy_btn_ui <- renderUI({ 
    req(input$device_lat)
    clip_text <- paste0("Lat: ", input$device_lat, ", Lng: ", input$device_lng, " (Acc: ", input$device_acc, "m)")
    rclipButton("clipbtn", "Copy Full Reading", clip_text, icon("clipboard"), class="btn-sm") 
  })
  
  output$accuracy_status <- renderUI({ 
    req(input$device_acc)
    if (input$device_acc <= target_acc_limit) {
      div(style = "color: green; font-weight: bold;", icon("check-double"), " Location Locked") 
    } else {
      div(style = "color: orange;", icon("sync", class = "fa-spin"), " Optimizing GPS...") 
    }
  })
  
  # --- 2. DATA LOADING ---
  observe({
    updateSelectInput(session, "country_file", choices = list.files("gadm_data", pattern = "\\.(shp|geojson)$"))
    updateSelectInput(session, "cluster_file", choices = list.files("cluster_data", pattern = "\\.(shp|geojson)$"))
  })
  
  loaded_layers <- eventReactive(input$load_data, {
    req(input$country_file, input$cluster_file)
    withProgress(message = 'Parsing Shapefiles...', value = 0.5, {
      list(
        country = st_read(file.path("gadm_data", input$country_file), quiet = TRUE) %>% st_transform(4326),
        cluster = st_read(file.path("cluster_data", input$cluster_file), quiet = TRUE) %>% st_transform(4326)
      )
    })
  })
  
  output$target_aez_ui <- renderUI({
    req(loaded_layers())
    df <- loaded_layers()$cluster
    col_name <- grep("cluster|AEZ", names(df), ignore.case = TRUE, value = TRUE)[1]
    req(col_name)
    choices <- sort(unique(as.character(df[[col_name]])))
    tagList(br(), h4("3. Target Validation"), selectInput("target_aez", "Target AEZ (Goal):", choices = choices))
  })
  
  # --- 3. FINAL DIAGNOSTIC REPORT ---
  output$analyze_button_ui <- renderUI({
    if (!isTRUE(input$gps_active) && isTruthy(input$device_acc) && !is.null(loaded_layers())) {
      actionButton("analyze", "Generate Diagnostic Report", class = "btn-primary btn-block", style = "height: 60px; font-weight: bold;")
    }
  })
  
  output$analysis_table <- renderTable({
    req(input$analyze, loaded_layers(), input$target_aez)
    
    pnt <- st_as_sf(data.frame(x = input$device_lng, y = input$device_lat), coords = c("x", "y"), crs = 4326)
    
    # Joins
    res_adm <- st_join(pnt, loaded_layers()$country, join = st_intersects)
    res_clus <- st_join(pnt, loaded_layers()$cluster, join = st_intersects)
    
    # Neighbor logic
    find_neighbors <- function(point, layer, col_pattern) {
      current_idx <- as.integer(st_intersects(point, layer))
      if (is.na(current_idx)) return("None")
      neighbors_idx <- st_touches(layer[current_idx, ], layer)[[1]]
      col_name <- grep(col_pattern, names(layer), ignore.case = TRUE, value = TRUE)[1]
      neighbor_names <- as.character(layer[[col_name]][neighbors_idx])
      if (length(neighbor_names) == 0) return("None found")
      return(paste(unique(neighbor_names), collapse = ", "))
    }
    
    # Distance to target
    cluster_df <- loaded_layers()$cluster
    clus_col <- grep("cluster|AEZ", names(cluster_df), ignore.case = TRUE, value = TRUE)[1]
    target_poly <- cluster_df[cluster_df[[clus_col]] == input$target_aez, ]
    dist_m <- as.numeric(min(st_distance(pnt, target_poly)))
    
    # Attribute helper
    get_v <- function(df, pat) {
      if (nrow(df) == 0) return("Outside Boundary")
      cn <- grep(pat, names(df), ignore.case = TRUE, value = TRUE)[1]
      if (is.na(cn)) return("Field Not Found")
      return(as.character(df[[cn]][1]))
    }
    
    data.frame(
      Metric = c("Country (NAME_0)", "Province (NAME_1)", "District (NAME_2)", "Ward (NAME_3)", 
                 "Detected AEZ", "Target AEZ", "Distance to Target", 
                 "Neighboring AEZs", "Neighboring Wards", 
                 "---",
                 "Captured Latitude", "Captured Longitude", "Capture Accuracy"),
      Result = c(
        get_v(res_adm, "NAME_0"), get_v(res_adm, "NAME_1"), get_v(res_adm, "NAME_2"), get_v(res_adm, "NAME_3"),
        get_v(res_clus, "cluster|AEZ"),
        as.character(input$target_aez),
        ifelse(dist_m < 1, "INSIDE TARGET", paste0(round(dist_m, 1), " m")),
        find_neighbors(pnt, loaded_layers()$cluster, "cluster|AEZ"),
        find_neighbors(pnt, loaded_layers()$country, "NAME_3"),
        "---",
        as.character(round(input$device_lat, 6)),
        as.character(round(input$device_lng, 6)),
        paste0("±", round(input$device_acc, 1), " m")
      )
    )
  }, striped = TRUE, bordered = TRUE)
  
  # --- 4. MAP ---
  output$map <- renderLeaflet({ leaflet() %>% addProviderTiles(providers$OpenStreetMap) %>% setView(0, 0, 2) })
  
  observeEvent(input$device_lat, {
    col <- if(input$device_acc <= target_acc_limit) "green" else "orange"
    leafletProxy("map") %>% clearGroup("pos") %>%
      addCircles(input$device_lng, input$device_lat, radius = input$device_acc, group = "pos", color = col) %>%
      addMarkers(input$device_lng, input$device_lat, group = "pos")
  })
  
  observeEvent(loaded_layers(), {
    leafletProxy("map") %>% clearGroup("shp") %>%
      addPolygons(data = loaded_layers()$country, group = "shp", color = "blue", weight = 1, fillOpacity = 0.05) %>%
      addPolygons(data = loaded_layers()$cluster, group = "shp", color = "red", weight = 2, fillOpacity = 0.1)
  })
}

shinyApp(ui, server)