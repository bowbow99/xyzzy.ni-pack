;;; -*- mode: lisp; package: ni-pack -*-
;;;
;;; ni-pack.l --- Create archive for NetInstaller
;;;
;;;
;;; Version: 0.0.0
;;; Category: Utility
;;; Depends:  ansify
;;;

;;; Commentary:
;;
;; Git���|�W�g������NetInstaller�p�̔z�z�����쐬���z�z�����X�g�t�@�C��
;; ���X�V�����ł��B

;;; Change Log:
;;
;; 2020-04-22 bowbow99 <bowbow99@gmail.com>
;; 	* �����i3��ځj

;;; Code:


;;;; * Dependencies and Package Definition

(eval-when (:execute :compile-toplevel :load-toplevel)
  (require "ansify"))

(defpackage :ni-pack
  (:use :lisp :editor
    :ansify.util))

(eval-when (:execute :compile-toplevel :load-toplevel)
  (ansify::install :ni-pack))

(in-package :ni-pack)


;;;; * User Configuration

(defvar *local-site-directory* (merge-pathnames "ni-site" (si:system-root))
  "*�z�z���Ɣz�z�����X�g�t�@�C����u���f�B���N�g���B")

(defvar *local-site-file* nil
  "*�z�z�����X�g�t�@�C���̖��O�B
nil �ł���� \"packages.l\" �ɂȂ�B")

(defvar *site-base-url* nil
  "*�z�z�������J����URL�B
�z�z����URL�� <ni-pack:*site-base-url*>/<NAME>-<VERSION>.zip �ɂȂ�B
nil �̏ꍇ�A�T�C�g��URL�i�z�z�����X�g�t�@�C���ɏ����Ă���j���g�p����B")

(defvar *temp-directory* nil
  "*�z�z���̃A�[�J�C�u���쐬����ۂɗ��p����ꎞ�f�B���N�g���B
nil �ł�������A���݂��Ȃ��f�B���N�g���̏ꍇ�A���ϐ� TMP ���g�p����B")

;;;;; Configuration Accessor

(defun local-site-directory ()
  (unless *local-site-directory*
    (restart-case
        (error "ni-pack:*local-site-directory* ���ݒ肳��Ă��܂���B")
      (store-value (pathname)
        :interactive (lambda ()
                       (read-directory-name "���[�J���T�C�g: "))
        :report "ni-pack:*local-site-directory* �̒l��ݒ肷��B"
        (setf *local-site-directory* pathname))))
  (cond ((file-directory-p *local-site-directory*))
        ((file-exist-p *local-site-directory*)
          (restart-case
              (error 'file-exists :pathname *local-site-directory*)
            (delete ()
              :report "�t�@�C�����폜���ăf�B���N�g�����쐬����B"
              (or (delete-file *local-site-directory*)
                  (error "�t�@�C�����폜�ł��܂���ł���: ~A" *local-site-directory*))
              (or (create-directory *local-site-directory*)
                  (error "�f�B���N�g�����쐬�ł��܂���ł���: ~A" *local-site-directory*)))))
        (t
          (or (create-directory *local-site-directory*)
              (error "�f�B���N�g�����쐬�ł��܂���ł���: ~A" *local-site-directory*))))
  *local-site-directory*)

(defun %local-site-file ()
  (or *local-site-file* "packages.l"))

(defun local-site-file ()
  (merge-pathnames (%local-site-file) (local-site-directory)))

(defun site-base-url (site)
  (or *site-base-url*
      (site-data site "url")))

(defun temp-directory ()
  (if (and *temp-directory*
           (file-directory-p *temp-directory*))
    *temp-directory*
    (si:getenv "TMP")))



;;;; * Utilities

;;;;; Anaphoric Macros

(defmacro awhile (condition &body body)
  `(let ((it nil))
     (while (setf it ,condition)
       ,@body)))

(defmacro awhen (condition &body body)
  `(let ((it ,condition))
     (if it
       (progn
         ,@body))))



;;;;; Dealing with List

(defmacro do-alist ((car cdr alist &optional (result nil)) &body body)
  `(dolist (#1=#:list ,alist ,result)
     (with-ca/dr (,car ,cdr)
         #1#
       ,@body)))


;;;; * Files and Buffers

(defmacro with-switch-to-buffer (buffer &body body)
  `(save-excursion
     (with-set-buffer
       (set-buffer ,buffer)
       ,@body)))

(defmacro with-temp-buffer ((var &optional (name "*TEMP*") &key (delete nil))
                            &body body)
  `(let ((,var (create-new-buffer ,name)))
     (setup-temp-buffer ,var)
     (unwind-protect
         (with-switch-to-buffer ,var
           ,@body)
       (when (and ,delete
                  (not (deleted-buffer-p ,var)))
         (delete-buffer ,var)))))

(defmacro with-load-file-contents ((buffer pathname) &body body)
  `(with-switch-to-buffer ,buffer
     (insert-file-contents ,pathname)
     ,@body))

(defmacro with-make-temp-file ((&rest bindings) &body body)
  `(let (,@(mapcar (lambda (binding)
                     (with-ca/dr (var args)
                         binding
                       `(,var (make-temp-file-name ,@args))))
                   bindings))
     (unwind-protect
         (progn ,@body)
       (dolist (tmp (list ,@(mapcar #'car bindings)))
         (or (delete-file tmp
                          :if-does-not-exist :skip
                          :if-access-denied :force)
             (cerror "�ꎞ�t�@�C�����폜�ł��܂���ł���: ~A" tmp))))))

(defun rm-rf (pathname)
  (labels ((rmdir (pathname)
             (dolist (x (directory pathname :absolute t))
               (rm-rf x))
             (delete-directory pathname)))
    (if (file-directory-p pathname)
      (rmdir pathname)
      (delete-file pathname))))


;;;;; * External Command

(define-condition command-failed (error)
  (command exit-code message)
  (:report (lambda (x out)
             (format out "Command failed: ~A ([~A] ~A)"
                     (command-failed-command x)
                     (command-failed-exit-code x)
                     (command-failed-message x)))))

(defun file-contents-of (pathname)
  (with-temp-buffer (buf)
    (with-load-file-contents (buf pathname)
      (buffer-substring (point-min) (point-max)))))

(defun exec (command &key (directory (default-directory)) (environ nil))
  (with-make-temp-file ((out "stdout" "tmp" (temp-directory))
                        (err "stderr" "tmp" (temp-directory)))
    (let ((exit-code
            (call-process command  :output out  :error err  :show :hide  :wait t
                          :exec-directory directory
                          :environ environ)))
      (if (zerop exit-code)
        (file-contents-of out)
        (error 'command-failed
          :command   command
          :exit-code exit-code
          :message   (file-contents-of err))))))


;;;; Git Repository

(defun repository-root (pathname)
  (labels ((abs-path (x)
             (merge-pathnames x pathname))
           (root-p (pathname)
             (and (every (lambda (x)
                           (file-directory-p (abs-path x)))
                         '(".git" "site-lisp"))
                  (every (lambda (x)
                           (file-exist-p (abs-path x)))
                         '("README.md" ".gitignore")))))
    (if (root-p pathname)
      pathname
      (let ((above (merge-pathnames ".." pathname)))
        ;; NOTE: merge-pathname returns "C:/" for "C:/" + ".."
        (unless (path-equal above pathname)
          (repository-root above))))))

(defun clone-repository (from to)
  (exec (format nil "git clone ~A ~A"
                (map-slash-to-backslash (truename from))
                (map-slash-to-backslash to))))

(defun clean-repository (repository)
  (dolist (pathname (directory repository :wild ".git*" :absolute t))
    (rm-rf pathname)))



;;;; * Site Data

(defconstant +site-data-keys+ '("name" "author" "url" "description" "packages"))

(defun site-data (site key &optional (no-error nil))
  (let ((found (assoc key site :test #'string=)))
    (cond (found
            (cdr found))
          (no-error
            nil)
          ((member key +site-data-keys+ :test #'string=)
            (error "Site data for ~S missing." key)))))

(defun load-site-data (pathname)
  (let ((site '()))
    (with-open-file (in pathname :direction :input)
      (awhile (read in nil nil)
        (push it site))
      (nreverse site))))

(defun print-site-data (site &optional (out *standard-output*))
  (let ((out (canonicalize-output-stream out)))
    (labels ((p (fmt &rest args)
               (apply #'format out fmt args))
             (print-packages (pkg-list)
               (p "(\"packages\"~%")
               (dolist (pkg pkg-list)
                 (p "~2& ;; ~A ver.~A~% (~S~{~%  ~S~})~%"
                    (pkg-data pkg "name")
                    (pkg-data pkg "version")
                    (car pkg)
                    (cdr pkg)))
               (p ") ;\"packages\" ends here.~%")))
      (do-alist (key value site)
        (if (string= key "packages")
          (print-packages value)
          (p "(~S . ~18T~S)~%" key value))))))

(defun save-site-data (site pathname)
  (with-open-file (out pathname :direction :output
                       :if-exists :overwrite
                       :if-does-not-exist :create)
    (format out ";;; -*- Mode: Lisp -*-~%")
    (print-site-data site out)))

(defun update-site-packages (site new-pkg)
  "Update or add NEW-PKG onto SITE."
  (labels ((pkg-name (pkg)
             (pkg-data pkg "name"))
           (update (new-pkg pkg-list)
             (let ((new-pkg-name (pkg-name new-pkg)))
               (cons new-pkg
                     (remove new-pkg-name pkg-list :key #'pkg-name :test #'string=)))))
    (let ((new '()))
      (do-alist (key value site)
        (if (string= key "packages")
          (push (cons key (update new-pkg value)) new)
          (push (cons key value) new)))
      (nreverse new))))


;;;;; Create Local Site

(defconstant +confirm-clean-format+
  "�f�B���N�g�� ~A �͋�ł͂���܂���B
�S�Ẵt�@�C���ƃT�u�f�B���N�g�����폜���܂����B

�폜����ꍇ�� [�͂�] �������Ă��������B
�폜�����i�t�@�C�����c�����܂܁j���[�J���T�C�g�Ƃ���ꍇ�� [������] �������Ă��������B
���[�J���T�C�g�̍쐬�𒆎~����ꍇ�� [�L�����Z��] �������Ă��������B")

(defun create-local-site (pathname name author url description &optional (site-file (%local-site-file)))
  (interactive "DDirectory: \nsName: \nsAuthor: \nsURL: \nsDescription: "
    :default0 (local-site-directory))
  (labels ((confirm-clean (pathname)
             (message-box (format nil +confirm-clean-format+ pathname)
                          "�f�B���N�g������ɂ��܂����H"
                          '(:yes-no-cancel :exclamation)))
           (prepare-directory (pathname interactive-p)
             (or (null (directory pathname))
                 (when interactive-p
                   (case (confirm-clean pathname)
                     (:yes (dolist (x (directory pathname))
                             (rm-rf x)))
                     (:no)
                     (:cancel
                       (quit)))))))
    (cond ((file-directory-p pathname)
            (prepare-directory pathname (interactive-p)))
          ((file-exist-p pathname)
            (if (and (interactive-p)
                     (eql (message-box "�t�@�C�� ~A �����݂��܂��B�폜���܂����H" '(:ok-cancel)) :ok))
              (delete-file pathname)
              (error 'file-exists :pathname pathname)))
          (t
            (create-directory pathname)))
    (let ((file (merge-pathnames (%local-site-file) pathname))
          (site `(("name"        . ,name)
                  ("author"      . ,author)
                  ("url"         . ,url)
                  ("description" . ,description)
                  ("packages"    . nil))))
      (save-site-data site file)
      (values site file))))



;;;; Package Data

(defconstant +package-data-keys+
  '("name" "version" "author" "file" "src" "description" "md5" "time" "depends"
    "category" "changes" "notice" "load-after-install" "load-before-uninstall"))

(defun pkg-data (pkg key &optional (no-error))
  (let ((found (assoc key pkg :test #'string=)))
    (cond (found
            (cdr found))
          (no-error
            nil)
          (t
            (error "Package data for ~S missing." key)))))

(defun sort-pkg-data (pkg)
  (labels ((key-order (a b)
             (member b (member a +package-data-keys+ :test #'string=) :test #'string=))
           (std-key-p (x)
             (member x +package-data-keys+ :test #'string=)))
    (let ((std   '())
          (extra '()))
      (dolist (x pkg)
        (if (std-key-p (car x))
          (push x std)
          (push x extra)))
      (append (sort std #'key-order :key #'car)
              (sort extra #'string< :key #'car)))))

(defun merge-pkg-data (pkg new-data)
  (dolist (new new-data)
    (setf pkg (cons new (remove (car new) pkg :key #'car))))
  (sort-pkg-data pkg))


;;;;; Gather Package Data: from Source File

(defparameter *source-header-definitions* nil)

(defun make-source-header-definition (name aliases scanner)
  (list name aliases scanner))

(defun *source-header-name    (def) (first def))
(defun *source-header-aliases (def) (second def))
(defun *source-header-scanner (def) (third def))

(defun find-source-header (label)
  (dolist (def *source-header-definitions*)
    (when (or (string-equal (*source-header-name def) label)
              (member label (*source-header-aliases def) :test #'string-equal))
      (return def))))

(let ((cached-regexp nil))
  (defun source-header-regexp ()
    (labels ((label-regexp (def)
               (format nil "~A~{\\|~A~}"
                       (*source-header-name def)
                       (*source-header-aliases def))))
      (or cached-regexp
          (let* ((labels (mapcar #'label-regexp *source-header-definitions*))
                 (fmt    ";;;[ \t]+\\(~{~A~^\\|~}\\):[ \t]*")
                 (regexp (format nil fmt labels)))
            (setf cached-regexp (compile-regexp regexp t)))))))

(defun !!invalid-header (label)
  (error "Invalid header: ~A" label))

(defvar *source-header-scanner-list* nil)

(defun find-source-header-scanner (type)
  (cdr (or (assoc type *source-header-scanner-list*)
           (error "Undefined scanner type: ~S" type))))

(defmacro define-header-scanner (type regexp n &rest more)
  `(let ((#1=#:scanner
           ,(if (and (stringp regexp)
                     (integerp n))
              `(lambda (label)
                 (if (looking-at ,regexp)
                   (match-string ,n)
                   (!!invalid-header label)))
              `(lambda ,regexp
                 ,@(cons n more)))))
     (setf *source-header-scanner-list*
           (cons (cons ',type #1#) (remove ',type *source-header-scanner-list* :key #'car)))))
(setf (get 'define-header-scanner 'ed:lisp-indent-hook) 1)

(define-header-scanner string   "\\([^\n]+\\)" 1)
(define-header-scanner version  "\\([0-9]+\\.[0-9]+\\.[0-9]+\\)" 1)
(define-header-scanner pathname "\\([^\n]+\\)" 1)

(define-header-scanner list (label)
  (if (looking-at "\\([^\n]+\\)")
    (split-string (match-string 1) #\Space)
    (!!invalid-header label)))

(define-header-scanner text (label)
  (unless (looking-for "\n")
    (!!invalid-header label))
  (forward-char 1)
  (let ((lines '()))
    (while (looking-at ";;\\(\\| [^\n]*\\)\n")
      (push (match-string 1) lines)
      (goto-char (match-end 0)))
    (format nil "~{~A~^\n~}" (nreverse lines))))

(defmacro define-source-header (name type &rest aliases)
  (let ((scanner `(find-source-header-scanner ',type)))
    `(setf *source-header-definitions*
           (cons (make-source-header-definition ,name ',aliases ,scanner)
                 (remove ,name *source-header-definitions* :key #'*source-header-name)))))
(setf (get 'define-source-header 'ed:lisp-indent-hook) 2)

(define-source-header "author"   string)
(define-source-header "version"  version)
(define-source-header "category" list)
(define-source-header "depends"  list)
(define-source-header "changes"  text  "Change Log" "ChangeLog" "History")
(define-source-header "notice"   text  "���ӎ���")
(define-source-header "load-after-install"    pathname)
(define-source-header "load-before-uninstall" pathname)
(define-source-header "description" text)

(define-source-header "build-script" pathname)
(define-source-header "build" list)

(defun pkg-data-from-source (pathname)
  (labels ((code-start ()
             (save-excursion
               (if (scan-buffer "^;;; Code:\n" :regexp t)
                 (match-end 0)
                 1000)))
           (module-name ()
             (save-excursion
               (if (or (scan-buffer "^(provide \"\\([^\"]+\\)\")" :regexp t)
                       (string-match "site-lisp/\\(.+\\).l$" pathname))
                 (match-string 1)
                 (error "Could not guess module name: ~A" pathname))))
           (find-header-label (limit)
             (let ((regexp (source-header-regexp)))
               (when (scan-buffer regexp :case-fold t :regexp t :limit limit)
                 (goto-char (match-end 0))
                 (match-string 1))))
           (scan-data (label)
             (let ((def (find-source-header label)))
               (unless def
                 (error "Unknown header: ~A" label))
               (values (*source-header-name def)
                       (funcall (*source-header-scanner def) label)))))
    (with-temp-buffer (buf (format nil "NI-Pack: ~A" pathname))
      (with-load-file-contents (buf pathname)
        (let ((pkg-data (list (cons "name" (module-name))))
              (limit    (code-start)))
          (goto-char (point-min))
          (awhile (find-header-label limit)
            (multiple-value-bind (label data)
                (scan-data it)
              (push (cons label data) pkg-data)))
          (nreverse pkg-data))))))

;;;;; Gather Package Data: from Archive

(defun pkg-data-from-archive (pathname)
  (unless (file-exist-p pathname)
    (error 'file-not-found :pathname pathname))
  (list (cons "md5"  (netinst::md5sum pathname))
        (cons "time" (file-write-time pathname))))

;;;;; Gather Package Data: from other data

(defun pkg-data-from-other-data (pkg site)
  (let* ((archive-name (format nil "~A-~A.zip"
                               (pkg-data pkg "name")
                               (pkg-data pkg "version")))
         (archive-url  (concat (site-base-url site)
                               archive-name)))
    (list (cons "file" archive-name)
          (cons "src"  archive-url))))


;;;; Build

;;;;; Builtin Build Functions

(defun compile-lisp-files (repository pkg)
  (dolist (src (directory (merge-pathnames "site-lisp" repository)
                          :absolute t  :recursive t  :wild "*.l"  :file-only t))
    (compile-file src)))

(defun move-toplevel-files (repository pkg)
  (let* ((name (pkg-data pkg "name"))
         (dest (merge-pathnames (format nil "site-lisp/~A" name) repository)))
    (unless (file-directory-p dest)
      (create-directory dest))
    (dolist (file (directory repository :file-only t))
      (let ((from (merge-pathnames file repository))
            (to   (merge-pathnames file dest)))
        (unless (rename-file from to)
          (error "Could not move file: ~A" file))))))


;;;; Release

(defun archive-pathname (pkg)
  (merge-pathnames (pkg-data pkg "file") (local-site-directory)))

(defun release (pathname)
  (interactive "F�t�@�C��: " :default0 (get-buffer-file-name))
  (let ((site (load-site-data (local-site-file)))
        (pkg  (pkg-data-from-source pathname))
        (pwd  (make-temp-file-name "ni-pack-" "tmp" (temp-directory) t))
        (repository (repository-root pathname)))
    (unwind-protect
        (progn
          (setf pkg (merge-pkg-data pkg (pkg-data-from-other-data pkg site)))
          (export-repository repository pwd)
          ;; FIXME: release: Run tests
          ;; Build
          (move-toplevel-files pwd pkg)
          (compile-lisp-files pwd pkg)
          ;; Create Archive
          (let* ((files   (directory pwd :recursive t  :file-only t :absolute t))
                 (archive (archive-pathname pkg)))
            (create-archive archive files pwd)
            ;; Update Local Site
            (let* ((pkg  (merge-pkg-data pkg (pkg-data-from-archive archive)))
                   (site (update-site-packages site pkg)))
              (save-site-data site (local-site-file))
              (values archive
                      pkg))))
      (rm-rf pwd))))






(provide "ni-pack")
;;; ni-pack.l ends here.