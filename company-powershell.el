;;; company-powershell --- Emacs autocompletion backend for powershell

;; Author: Noah Peart <noah.v.peart@gmail.com>
;; URL: https://github.com/nverno/company-powershell
;; Package-Requires: ((emacs "24.3") (cl-lib "0.5") (company-mode "0.9")) 
;; Copyright (C) 2016, Noah Peart, all rights reserved.
;; Created: 23 September 2016

;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Description:

;;  Company autocompletion backend for powershell.  It will ask to create an
;;  index of commands when first invoked.  This takes a while, so `company-powershell'
;;  completion will disable itself until the process is finished.
;;
;;  `company-show-location' ("M-.") looks up the online help in the browser
;;  for the completion
;;  candidate if available.

;; Example:

;; ![example](ex/example.png)

;;; Code:
(eval-when-compile
  (require 'cl-lib))
(require 'subr-x)
(require 'company)

(defgroup company-powershell nil
  "company backend for powershell"
  :group 'company)

(defcustom company-powershell-ignore-case t
  "Ignore case during completion."
  :type 'boolean
  :group 'company-powershell)

(defvar company-powershell-data-file "commands.dat"
  "File to store with command info.")

(defvar company-powershell-build-script "commands.ps1"
  "Script to build command index.")

(defvar company-powershell-dir)
(setq company-powershell-dir
      (when load-file-name (file-name-directory load-file-name)))

;; ------------------------------------------------------------

(defvar company-powershell--enabled t)
(defun company-powershell--load ()
  "Load / build command index."
  (let ((data (expand-file-name company-powershell-data-file
                                company-powershell-dir))
        (script (expand-file-name company-powershell-build-script
                                  company-powershell-dir)))
    (when company-powershell--enabled
      (when (not (file-exists-p data))
        (setq company-powershell--enabled nil)
        (let ((do-it (y-or-n-p "Generate command index?")))
          (if do-it
              (company-powershell--build-index data script)
            (user-error "Disabling `company-powershell'."))))
      (and company-powershell--enabled
           (file-exists-p data)
           (with-temp-buffer
             (insert-file-contents data)
             (car (read-from-string
                   (buffer-substring-no-properties (point-min) (point-max)))))))))

(defun company-powershell--build-index (file script)
  "Generate command index for completion."
  (let ((proc (start-process "company-powershell" "*company-powershell build*"
                             "powershell" "-f" script file)))
    (message "Generating command index, disabling completion until finished.")
    (set-process-sentinel proc #'company-powershell--build-sentinel)))

(defun company-powershell--build-sentinel (p s)
  (message "%s: %s" (process-name p) (replace-regexp-in-string "\n" "" s))
  (when (eq 0 (process-exit-status p))
    (setq company-powershell--enabled t)
    (company-powershell--keywords)))

(defvar company-powershell--keywords nil)
(defun company-powershell--keywords ()
  (when company-powershell--enabled
    (or company-powershell--keywords
        (setq company-powershell--keywords
              (let ((data (company-powershell--load)))
                (sort
                 (cl-loop for (cmd type uri syn) in data
                    do
                      (add-text-properties 0 1
                                           (list
                                            'annot type
                                            'synopsis syn
                                            'help uri)
                                           cmd)
                    collect cmd)
                 'string<))))))

(defun company-powershell--prefix ()
  (and (eq major-mode 'powershell-mode)
       company-powershell--enabled
       (not (company-in-string-or-comment))
       (company-grab-symbol)))

(defun company-powershell--candidates (arg)
  (let ((completion-ignore-case company-powershell-ignore-case))
    (all-completions arg (company-powershell--keywords))))

(defun company-powershell--annotation (candidate)
  (or (get-text-property 0 'annot candidate) ""))

(defun company-powershell--doc (candidate)
  (let* ((syn (get-text-property 0 'synopsis candidate))
         (syn (or (and (string= "" syn) "No documentation")
                  (string-trim syn))))
    (company-doc-buffer syn)))

(defun company-powershell--meta (candidate)
  (get-text-property 0 'synopsis candidate))

(defun company-powershell--online (candidate)
  "Lookup help for candidate online."
  (let ((uri (get-text-property 0 'help candidate)))
    (if (not (string= "" uri))
        (browse-url uri)
      (user-error "No help uri for %s" candidate))))

;;;###autoload
(defun company-powershell (command &optional arg &rest _args)
  "`company-mode' completion for powershell."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-powershell))
    (prefix (company-powershell--prefix))
    (annotation (company-powershell--annotation arg))
    (candidates (company-powershell--candidates arg))
    (doc-buffer (company-powershell--doc arg))
    (meta (company-powershell--meta arg))
    (location (company-powershell--online arg))
    (require-match 'never)
    (sorted t)
    (ignore-case company-powershell-ignore-case)))

(provide 'company-powershell)
;;; company-powershell.el ends here
