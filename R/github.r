#' Get GitHub metrics on a user or organization's repositories.
#' 
#' @import httr
#' @param userorg User or organization GitHub name.
#' @param repo Repository name.
#' @param return_ what to return, one of: show (raw data), allstats, watchers, open_issues, or forks
#' @return json
#' @examples \dontrun{
#' github_auth()
#' options(useragent='ropensci')
#' github_repo(userorg = 'ropensci', repo = 'rmendeley')
#' github_repo(userorg = 'hadley', repo = 'ggplot2')
#' github_repo(userorg = 'hadley', repo = 'ggplot2', 'allstats')
#' github_repo(userorg = 'hadley', repo = 'ggplot2', return_ = 'forks')
#' }
#' @export
github_repo <- function(userorg = NA, repo = NA, return_ = 'show')
{
  useragent <- getOption('useragent')
  if(is.null(useragent))
    stop('You must provide a User-Agent string')
  
  access_token <- getOption('github_token')
  if(is.null(access_token))
    stop('You must authenticate with Github first, see github_auth()')
  
	url = "https://api.github.com/repos/"
	url2 <- paste(url, userorg, '/', repo, sep='')
  args <- list(access_token=access_token)
  tt = content(GET(url2, add_headers('User-Agent' = useragent), query=args))
# 	tt = content(GET(url2, session))
	if(return_=='show'){tt} else
	if(return_=='allstats'){
    	list('watchers'=tt$watchers, 'open_issues'=tt$open_issues, 
        	 'forks'=tt$forks)} else
  	if(return_=='watchers'){tt$watchers} else
    	if(return_=='open_issues'){tt$open_issues} else
      		if(return_=='forks'){tt$forks}
}

#' Get GitHub metrics on a user or organization's repositories.
#' 
#' @import httr
#' @param userorg User or organization GitHub name.
#' @param type One of user or org (defaults to org)
#' @param repo Repository name.
#' @param per_page (optional) Number of results to return
#' @return Vector of names or repos for organization or user.
#' @examples \dontrun{
#' github_auth()
#' options(useragent='ropensci')
#' github_allrepos(userorg = 'ropensci')
#' }
#' @export
github_allrepos <- function(userorg = NA, type = 'org', return_ = 'names', per_page = 100)
{
  useragent <- getOption('useragent')
  if(is.null(useragent))
    stop('You must provide a User-Agent string')
  
  access_token <- getOption('github_token')
  if(is.null(access_token))
    stop('You must authenticate with Github first, see github_auth()')
  
  url = "https://api.github.com/"
  if(type == 'org'){
    url2 <- paste0(url, 'orgs/', userorg, '/repos')
  } else
  { url2 <- paste0(url, 'users/', userorg, '/repos') }
  args <- list(access_token=access_token, per_page=per_page)
  tt = content(GET(url2, add_headers('User-Agent' = useragent), query=args))
#   url2 <- paste(url, userorg, '/repos?per_page=100', sep='')
#   tt = content(GET(url2, config=session, user_agent('rOpenSci')))
#   tt = content(GET(url2, user_agent('rOpenSci')))
  if(return_=='show'){tt} else
    if(return_=='names'){
        sapply(tt, function(x) x$name)
    } else
      { NULL }
}

#' Authenticate with github
#' @import httr
#' @param client_id Consumer key. can be supplied here or read from Options()
#' @param client_secret Consumer secret. can be supplied here or read from Options()
#' @param scope Comma separated list of scopes. One or more of: user, user:email, 
#' 		user:follow, public_repo, repo, repo:status, delete_repo, notifications, gist
#' @examples \dontrun{
#' github_auth()
#' }
#' @export
github_auth <- function(client_id = NULL, client_secret = NULL, scope = NULL)
{
	if(!is.null(client_id)) {client_id=client_id} 
		else {client_id = getOption("github_client_id", stop("Missing Github client id"))}
	if(!is.null(client_secret)) {client_secret=client_secret} 
		else {client_secret = getOption("github_client_secret", stop("Missing Github client secret"))}
	if(!exists("github_sign")){
		github_app <- oauth_app("github", key=client_id, secret=client_secret)
		github_urls <- oauth_endpoint(NULL, "authorize", "access_token", base_url = "https://github.com/login/oauth")
		github_token <- oauth2.0_token(github_urls, github_app, scope = scope)
    options(github_token = github_token$access_token)
# 		github_sign <- httr::sign_oauth2.0(github_token$access_token)
# 		assign('github_sign', github_sign, envir=sandbox:::GitHubAuthCache)
# 		message("\n GitHub authentication was successful \n")
# 		invisible(github_sign)
	} else { NULL }
}

#' Helper function to get authentication
#'
#' The authentication environment is created by new.env function in the zzz.R file.  
#' The authentication token 'oauth' is created by the github_auth() function.  
#' This helper function lets all other functions load the authentication.  
#' @keywords internal
github_get_auth <- function(...)
{
#   if(!exists("github_sign", envir=sandbox:::GitHubAuthCache))
#     tryCatch(github_auth(...), error= function(e) 
#       stop("Requires authentication. 
#       Are your credentials stored in options? 
#       See github_auth function for details."))
#   get("github_sign", envir=sandbox:::GitHubAuthCache)
  message("deprecated")
}

#' Get GitHub metrics on a user or organization's repositories.
#' 
#' @import plyr ggplot2 httr lubridate reshape2
#' @param userorg User or organization GitHub name.
#' @param repo Repository name.
#' @param since Date to start at.
#' @param until Date to stop at.
#' @param author Specify a committer, if none, will return all.
#' @param limit Number of commits to return per call
#' @param sha The commit sha to start returning commits from.
#' @param timeplot Make a ggplot2 plot visualizing additions and deletions by user. Defaults to FALSE.
#' @return data.frame or ggplot2 figure.
#' @examples \dontrun{
#' github_commits(userorg = 'ropensci', repo = 'rmendeley')
#' github_commits(userorg = 'ropensci', repo = 'rfigshare', since='2009-01-01T')
#' github_commits(userorg = 'ropensci', repo = 'taxize_', since='2009-01-01T', limit=500, timeplot=TRUE)
#' }
#' @export
github_commits <- function(userorg = NA, repo = NA, since = NULL, until = NULL,
	author = NULL, limit = 100, sha = NULL, timeplot = FALSE)
{	
# 	session = sandbox:::github_get_auth()
  useragent <- getOption('useragent')
  if(is.null(useragent))
    stop('You must provide a User-Agent string')
  
  access_token <- getOption('github_token')
  if(is.null(access_token))
    stop('You must authenticate with Github first, see github_auth()')
  
	url = "https://api.github.com/repos/"
	url2 <- paste0(url, userorg, '/', repo, '/commits')
	if(limit > 100) {per_page = 100} else {per_page = limit}

	if(limit > 100) {
		tt <- list()
		shavec <- list("youdummy")
		iter = 0
		iter_ = 1
		status = "notdone"
		while(status == "notdone"){
			iter <- iter + 1
			iter_ <- iter_ + 1
			args <- compact(list(since = since, until = until, author = author, per_page = per_page, sha = sha, access_token=access_token))
# 			out <- content(GET(url2, session, query=args))
# 			tt = content(GET(url2, user_agent('rOpenSci'), query=args))
			tt <- content(GET(url2, add_headers('User-Agent' = useragent), query=args))
			sha <- out[[length(out)]]$sha; since = NULL; until = NULL
			# sha <- out[[length(out)]]$sha
			shavec[[iter_]] <- sha
			if(shavec[[(length(shavec)-1)]] == shavec[[length(shavec)]]) { status = "done" } else
			{
				tt[[iter]] <- out
			}
		}
		
		tt <- do.call(c, tt)
	} else
	{
		args <- compact(list(since = since, until = until, author = author, per_page = per_page, sha = sha, access_token=access_token))
		tt <- content(GET(url2, add_headers('User-Agent' = useragent), query=args))
# 		tt = content(GET(url2, session, query=args))
# 		tt = content(GET(url2, user_agent('rOpenSci'), query=args))
	}
	
	shas <- unique(laply(tt, function(x) x$sha))
	getstats <- function(x){
# 		tempist <- content(GET(paste0(url2,"/",x), session))
		tempist <- content(GET(paste0(url2,"/",x), user_agent('rOpenSci')))
		c(tempist$sha, tempist$stats[[2]], tempist$stats[[3]])
	}
	stats <- llply(shas, getstats)
	statsdf <- ldply(stats)
	statsdf <- colClasses(statsdf, c("character","numeric","numeric"))
	
	forceit <- function(x){
		dd <- c(x$sha, x$commit$committer[["date"]], x$committer$login)
		if(!length(dd)==3){ c(dd, "whoknowshit") } else
			{ dd }
	}
	temp <- ldply(tt, forceit)
	names(temp) <- c("sha","date","name")
	temp$name <- as.factor(temp$name)
	temp$date <- as.Date(temp$date)
	temp <- temp[!duplicated(temp),]

	alldat <- merge(statsdf, temp, by.x="V1", by.y="sha")
	alldat <- alldat[,-1] # drop sha column
	names(alldat)[1:2] <- c("additions","deletions")

	alldat_m <- melt(alldat, id=3:4)
	
	if(!timeplot){ alldat_m } else
	{
		ggplot(alldat_m, aes(date, value, colour=name)) +
			geom_line() +
			scale_x_date() +
			facet_grid(variable ~ .) + 
			labs(x="", y="")
		
	}
}


#' Create time series bar plot.
#' 
#' @import plyr ggplot2 reshape2 ggthemes
#' @param data Data set to plot with.
#' @examples \dontrun{
#' # Run with example data set (commits from the ropensci organization account)
#' github_timeseries()
#' 
#' # Get your own data
#' github_auth()
#' mydat <- llply(c('ggplot2','plyr','httr'), function(x) github_commits(userorg='hadley',repo=x,limit=500))
#' mydat <- ldply(mydat)
#' github_timeseries(mydat)
#' }
#' @export
github_timeseries <- function(data = NULL)
{	
	data(ropensci_commits) # load data set
	ropensci_commits$date <- as.Date(as.character(ropensci_commits$date))
	dframe <- ropensci_commits[!ropensci_commits$.id %in% c("citeulike", "challenge", "docs", "ropensci-book", 
		"usecases", "textmine", "usgs", "ropenscitoolkit", "neotoma", "rEWDB", "rgauges", 
		"rodash", "ropensci.github.com", "ROAuth"), ]
	dframe$.id <- tolower(dframe$.id)
	dframe <- ddply(dframe, .(.id, date), summarise, value = sum(value))

	mindates <- llply(unique(dframe$.id), function(x) min(dframe[dframe$.id == x, "date"]))
	names(mindates) <- unique(dframe$.id)
	mindates <- sort(do.call(c, mindates))
	dframe$.id <- factor(dframe$.id, levels = names(mindates))

	ggplot(dframe, aes(date, value, fill = .id)) + 
		geom_bar(stat = "identity", width = 0.5) + 
		geom_rangeframe(sides = "b", colour = "grey") + 
		theme_bw(base_size = 9) + 
		scale_x_date(labels = date_format("%Y"), breaks = date_breaks("year")) + 
		scale_y_log10() + 
		facet_grid(.id ~ .) + 
		labs(x = "", y = "") + 
		theme(axis.text.y = element_blank(), 
			axis.text.x = element_text(colour = "black"), 
			axis.ticks.y = element_blank(), 
			strip.text.y = element_text(angle = 0, size = 8, ), 
			strip.background = element_rect(size = 0), 
			panel.grid.major = element_blank(), 
			panel.grid.minor = element_blank(), 
			legend.text = element_text(size = 8), 
			legend.position = "none", 
			panel.border = element_blank())
}


#' Create a new github repo.
#' 
#' @import plyr httr
#' @param userorg User or organization GitHub name.
#' @param name Your new repo name. Required
#' @param description Description of repo. Optional
#' @param homepage Homepage for repo. Optional
#' @param private Make the repo private? Creating private repositories requires a paid GitHub account.
#' @param has_issues true to enable issues for this repository, false to disable them. 
#' @param has_wiki true to enable the wiki for this repository, false to disable it
#' @param has_downloads true to enable downloads for this repository, false to disable them. 
#' @param team_id The id of the team that will be granted access to this repository. This is only valid when creating a repo in an organization.
#' @param auto_init true to create an initial commit with empty README. Default is False.
#' @param gitignore_template See \link{https://github.com/github/gitignore}
#' @param session (optional) the authentication credentials from \code{\link{github_auth}}. 
#'		If not provided, will attempt to load from cache as long as github_auth has been run. 
#' @examples \dontrun{
#' github_auth(scope='repo')
#' options(useragent='ropensci')
#' github_create_repo(user='schamberlain', name='test')
#' 
#' github_create_repo(user='schamberlain', name='test', description='testing', homepage='http://schamberlain.github.com/scott/')
#' }
#' @export
github_create_repo <- function(user=NULL, org=NULL, name=NULL, description=NULL, 
	homepage=NULL, private='False', has_issues='True', has_wiki='True', 
	has_downloads='True', team_id=NULL, auto_init='False', 
	gitignore_template=NULL)
{
	message("this function doesn't currently work")
# 	session = sandbox:::github_get_auth(scope='repo')
#   useragent <- getOption('useragent')
#   if(is.null(useragent))
#     stop('You must provide a User-Agent string')
#   
#   access_token <- getOption('github_token')
#   if(is.null(access_token))
#     stop('You must authenticate with Github first, see github_auth()')
#   
# 	url = "https://api.github.com/"
# 	if(!is.null(user))
# 		# url2 <- paste(url, user, '/repos', sep='')
# 		url2 <- paste0(url, 'user/repos?access_token=', access_token)
# 	if(!is.null(org))
# 		  url2 <- paste0(url, 'orgs/', org, '/repos?access_token=', access_token)
# 	args <- compact(list(name=name, description=description, homepage=homepage, 
# 		private=private, has_issues=has_issues, has_wiki=has_wiki, 
# 		has_downloads=has_downloads, team_id=team_id, auto_init=auto_init, 
# 		gitignore_template=gitignore_template, access_token=access_token))	
#   tt <- content(POST(url2, config=add_headers('User-Agent' = useragent), body=args))
# 	return( tt )
}

#' Coerces data.frame columns to the specified classes
#' 
#' @param d A data.frame.
#' @param colClasses A vector of column attributes, one of: 
#'    numeric, factor, character, etc.
#' @examples
#' dat <- data.frame(xvar = seq(1:10), yvar = rep(c("a","b"),5)) # make a data.frame
#' str(dat)
#' str(colClasses(dat, c("factor","factor")))
#' @export
colClasses <- function(d, colClasses) {
  colClasses <- rep(colClasses, len=length(d))
  d[] <- lapply(seq_along(d), function(i) switch(colClasses[i], 
      numeric=as.numeric(d[[i]]), 
      character=as.character(d[[i]]), 
      Date=as.Date(d[[i]], origin='1970-01-01'), 
      POSIXct=as.POSIXct(d[[i]], origin='1970-01-01'), 
      factor=as.factor(d[[i]]),
      as(d[[i]], colClasses[i]) ))
  d
}