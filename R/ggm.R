#' Visualization of EGMs using `ggplot`
#'
#' `r lifecycle::badge("experimental")`
#'
#' @param data Data of the `egm` class, which inclues header (meta) and signal
#'   information together.
#'
#' @param channels Character vector of which channels to use. Can give either
#'   the channel label (e.g "CS 1-2") or the recording device/catheter type (e.g
#'   "His" or "ECG").
#'
#' @param time_frame A time range that should be displaced given in the format
#'   of a vector with a length of 2. The left value is the start, and right
#'   value is the end time. This is given in seconds (decimals may be used).
#'
#' @param annotation_channel Identifies which of the selected channels will be
#'   used for annotation. This channel will be used for the analysis of
#'   intervals, peaks, etc. If NULL, no annotations will be made.
#'
#' @import ggplot2 data.table
#' @export
ggm <- function(data,
								channels,
								time_frame = NULL,
								...) {

	stopifnot(inherits(data, "egm"))

	header <- data$header
	signal <- data$signal

	# Should be all of the same frequency of data
	hz <- unique(header$freq)
	signal$index <- 1:nrow(signal)
	signal$time <- signal$index / hz

	# Check if time frame exists within series
	if (is.null(time_frame)) {
		time_frame <- c(min(signal$time, na.rm = TRUE), max(signal$time, na.rm = TRUE))
	}
	stopifnot("`time_frame` must be within available data" =
							all(time_frame %in% signal$time))

	# Filter appropriately
	start_time <- time_frame[1]
	end_time <- time_frame[2]
	ch <- channels
	surface_leads <- c("I", "II", "III", paste0("V", 1:6), "AVF", "AVR", "AVR")
	ch_exact <- ch[which(ch %in% surface_leads | grepl("\ ", ch))]
	ch_fuzzy <- ch[which(!(ch %in% ch_exact))]
	ch_grep <-
		paste0(c(paste0("^", ch_exact, "$", collapse = "|"), ch_fuzzy),
					 collapse = "|")

	# Lengthen for plotting
	dt <-
		melt(
			signal,
			id.vars = c("index", "time"),
			variable.name = "label",
			value.name = "mV"
		) |>
		{\(.x)
			header[.x, on = .(label)]
		}() |>
		{\(.y)
			.y[grepl(ch_grep, label),
					][time >= start_time & time <= end_time,
					]
		}()


	# Relevel
	dt$label <- factor(dt$label, levels = levels(header$label))

	# Final channels
	chs <- unique(dt$label)

	g <-
		ggplot(dt, aes(x = time, y = mV, color = color)) +
		geom_line() +
		facet_wrap( ~ label,
								ncol = 1,
								scales = "free_y",
								strip.position = "left") +
		scale_color_identity() +
		theme_egm() +
		scale_x_continuous(breaks = seq(time_frame[1], time_frame[2], by = 0.2),
											 label = NULL)

	# Return with updated class
	new_ggm(g)

}

#' Construct `ggm` class
new_ggm <- function(object = ggplot()) {

	stopifnot(is.ggplot(object))

	structure(
		object,
		class = c("ggm", class(object))
	)
}

#' Add intervals
#'
#' @param intervals The choice of whether interval data will be included. An
#'   annotation channel must be present, otherwise nothing will be plotted. This
#'   argument allows several choices.
#'
#'   * __TRUE__: all intervals will be annotated (default option)
#'
#'   * __integer__: an integer vector that represents the indexed intervals that
#'   should be annotated. If NULL, no intervals will be annotated. For example,
#'   if their are 5 beats, than there are 4 intervals between them that can be
#'   labeled. They can be referenced by their index, e.g. `intervals = c(2)` to
#'   reference the 2nd interval in a 5 beat range.
#' @export
add_intervals <- function(object,
													intervals = TRUE,
													channel,
													minimum_interval = 100) {

	# Initial validation
	stopifnot("`add_intervals()` requires a `ggm` object" = inherits(object, "ggm"))

	# Get channels and check
	dt <- object$data
	chs <- unique(dt$label)
	stopifnot("The channel must be in the plot to annotate." = channel %in% chs)
	hz <- unique(dt$freq)

	# Subset data for an annotation channel
	ann <- dt[label == channel]
	t <- ann$index
	peaks <-
		gsignal::findpeaks(
			ann$mV,
			MinPeakHeight = quantile(ann$mV, probs = 0.99),
			MinPeakDistance = minimum_interval,
			DoubleSided = TRUE
		)

	# Find peaks and intervals, and trim data for mapping purposes
	pk_locs <- ann$time[peaks$loc]
	ints <- diff(peaks$loc)
	ints_locs <- pk_locs[1:length(ints)] + ints/(2 * hz)
	ht <- mean(abs(peaks$pks), na.rm = TRUE)


	dt_locs <- round(ints_locs*hz, digits = 0)
	dt_ann <- ann[dt_locs, ]

	# Interval validation
	stopifnot(inherits(as.integer(intervals), "integer"))
	stopifnot("Intervals not available based on number of beats." =
							all(intervals %in% seq_along(ints)))

	# For all intervals
	if (isTRUE(intervals)) {

		n <- seq_along(ints)

		gtxt <- lapply(n, function(.x) {
			geom_text(
				data = dt_ann,
				aes(
					x = ints_locs[.x],
					y = ht / 2,
					label = ints[.x]
				),
				color = "black",
				inherit.aes = FALSE
			)
		})

	# Selected intervals
	} else if (inherits(as.integer(intervals), "integer")) {

		gtxt <- lapply(intervals, function(.x) {
			geom_text(
				data = dt_ann,
				aes(
					x = ints_locs[.x],
					y = ht / 2,
					label = ints[.x]
				),
				color = "black",
				inherit.aes = FALSE
			)
		})

	}

	# Return updated plot
	object + gtxt
}


#' Custom theme for EGM data
#' @export
theme_egm <- function() {
	font <- "Arial"
	theme_minimal() %+replace%
		theme(

			# Panels
			panel.grid.major.y = element_blank(),
			panel.grid.minor.y = element_blank(),
			panel.grid.major.x = element_blank(),
			panel.grid.minor.x = element_blank(),

			# Axes
			axis.ticks.y = element_blank(),
			axis.title.y = element_blank(),
			axis.text.y = element_blank(),
			axis.title.x = element_blank(),
			axis.ticks.x = element_line(),

			# Facets
			panel.spacing = unit(0, units = "npc"),
			panel.background = element_blank(),
			strip.text.y.left = element_text(angle = 0, hjust = 1),

			# Legend
			legend.position = "none"
		)
}