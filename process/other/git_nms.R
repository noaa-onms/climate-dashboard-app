librarian::shelf(dplyr, fs, glue, here, logger, tibble)

d <- tibble(
  dir = dir_ls(here("data/copernicus_phy"))) |>
    tibble::rowid_to_column("rowid") |>
  filter(rowid >= 5)

# sequence along tibble
for (i in 1:nrow(d)){ # i = 12
  dir <- d$dir[i]
  # git add the dir
  log_info(glue("start git {basename(dir)}"))

  system(glue("git add {dir}"))
  system(glue("git commit -m 'cm {basename(dir)}'"))
  system(glue("git push"))

  log_info(glue("finish git {basename(dir)}"))
}

# be746ef0d9d8a22948811c1642686bf692bd2d62
# cmt <- "7f393a94f6fdc11063a902b9c262c8019a014ca0"
# system(glue("git push origin {cmt}:main"))
#
# # Start from a clean state
# git fetch origin
# git checkout main
# git reset --hard origin/main
#
# # Cherry-pick commits one by one
# git cherry-pick 7f393a94f6fdc11063a902b9c262c8019a014ca0
# git push origin main
#
# # Then continue with the next commit
# git cherry-pick <next-commit-sha>
#   git push origin main
#
#



