namespace setBumpmap
{
    partial class Form1
    {
        /// <summary>
        /// Erforderliche Designervariable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Verwendete Ressourcen bereinigen.
        /// </summary>
        /// <param name="disposing">True, wenn verwaltete Ressourcen gelöscht werden sollen; andernfalls False.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Vom Windows Form-Designer generierter Code

        /// <summary>
        /// Erforderliche Methode für die Designerunterstützung.
        /// Der Inhalt der Methode darf nicht mit dem Code-Editor geändert werden.
        /// </summary>
        private void InitializeComponent()
        {
            this.btn_dae = new System.Windows.Forms.Button();
            this.btn_bumpmap = new System.Windows.Forms.Button();
            this.richTextBox1 = new System.Windows.Forms.RichTextBox();
            this.btn_diffusemap = new System.Windows.Forms.Button();
            this.picBoxDiff = new System.Windows.Forms.PictureBox();
            this.label1 = new System.Windows.Forms.Label();
            this.bnt_clearbump = new System.Windows.Forms.Button();
            this.bnt_cleardiffuse = new System.Windows.Forms.Button();
            this.btn_relativ = new System.Windows.Forms.Button();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.picBoxBump = new System.Windows.Forms.PictureBox();
            this.groupBox_Textures2 = new System.Windows.Forms.GroupBox();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.picBoxTrans = new System.Windows.Forms.PictureBox();
            this.btn_transparentmap = new System.Windows.Forms.Button();
            this.bnt_cleartransparent = new System.Windows.Forms.Button();
            this.groupBox4 = new System.Windows.Forms.GroupBox();
            this.picBoxSpec = new System.Windows.Forms.PictureBox();
            this.btn_specularmap = new System.Windows.Forms.Button();
            this.btn_clearspec = new System.Windows.Forms.Button();
            this.groupBox5 = new System.Windows.Forms.GroupBox();
            this.picBoxAmbient = new System.Windows.Forms.PictureBox();
            this.btn_ambientmap = new System.Windows.Forms.Button();
            this.btn_clearambient = new System.Windows.Forms.Button();
            this.groupBox6 = new System.Windows.Forms.GroupBox();
            this.picBoxReflec = new System.Windows.Forms.PictureBox();
            this.btn_reflectivemap = new System.Windows.Forms.Button();
            this.btn_clreareflective = new System.Windows.Forms.Button();
            this.groupBox_Textures = new System.Windows.Forms.GroupBox();
            ((System.ComponentModel.ISupportInitialize)(this.picBoxDiff)).BeginInit();
            this.groupBox1.SuspendLayout();
            this.groupBox2.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.picBoxBump)).BeginInit();
            this.groupBox_Textures2.SuspendLayout();
            this.groupBox3.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.picBoxTrans)).BeginInit();
            this.groupBox4.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.picBoxSpec)).BeginInit();
            this.groupBox5.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.picBoxAmbient)).BeginInit();
            this.groupBox6.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.picBoxReflec)).BeginInit();
            this.groupBox_Textures.SuspendLayout();
            this.SuspendLayout();
            // 
            // btn_dae
            // 
            this.btn_dae.AllowDrop = true;
            this.btn_dae.Location = new System.Drawing.Point(12, 12);
            this.btn_dae.Name = "btn_dae";
            this.btn_dae.Size = new System.Drawing.Size(150, 60);
            this.btn_dae.TabIndex = 0;
            this.btn_dae.Text = "drop your Modelfile here";
            this.btn_dae.UseVisualStyleBackColor = true;
            this.btn_dae.Click += new System.EventHandler(this.btn_dae_Click);
            this.btn_dae.DragDrop += new System.Windows.Forms.DragEventHandler(this.btn_dae_DragDrop);
            this.btn_dae.DragEnter += new System.Windows.Forms.DragEventHandler(this.btn_dae_DragEnter);
            // 
            // btn_bumpmap
            // 
            this.btn_bumpmap.AllowDrop = true;
            this.btn_bumpmap.Location = new System.Drawing.Point(76, 19);
            this.btn_bumpmap.Name = "btn_bumpmap";
            this.btn_bumpmap.Size = new System.Drawing.Size(144, 23);
            this.btn_bumpmap.TabIndex = 0;
            this.btn_bumpmap.Text = "drop the bumpmap here";
            this.btn_bumpmap.UseVisualStyleBackColor = true;
            this.btn_bumpmap.Click += new System.EventHandler(this.btn_bumpmap_Click);
            this.btn_bumpmap.DragDrop += new System.Windows.Forms.DragEventHandler(this.btn_bumpmap_DragDrop);
            this.btn_bumpmap.DragEnter += new System.Windows.Forms.DragEventHandler(this.btn_bumpmap_DragEnter);
            // 
            // richTextBox1
            // 
            this.richTextBox1.Location = new System.Drawing.Point(12, 95);
            this.richTextBox1.Name = "richTextBox1";
            this.richTextBox1.ReadOnly = true;
            this.richTextBox1.Size = new System.Drawing.Size(260, 119);
            this.richTextBox1.TabIndex = 1;
            this.richTextBox1.Text = "";
            // 
            // btn_diffusemap
            // 
            this.btn_diffusemap.AllowDrop = true;
            this.btn_diffusemap.Location = new System.Drawing.Point(76, 19);
            this.btn_diffusemap.Name = "btn_diffusemap";
            this.btn_diffusemap.Size = new System.Drawing.Size(144, 23);
            this.btn_diffusemap.TabIndex = 2;
            this.btn_diffusemap.Text = "drop the diffusemap here";
            this.btn_diffusemap.UseVisualStyleBackColor = true;
            this.btn_diffusemap.DragDrop += new System.Windows.Forms.DragEventHandler(this.btn_diffusemap_DragDrop);
            this.btn_diffusemap.DragEnter += new System.Windows.Forms.DragEventHandler(this.btn_diffusemap_DragEnter);
            // 
            // picBoxDiff
            // 
            this.picBoxDiff.Location = new System.Drawing.Point(6, 19);
            this.picBoxDiff.Name = "picBoxDiff";
            this.picBoxDiff.Size = new System.Drawing.Size(64, 64);
            this.picBoxDiff.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picBoxDiff.TabIndex = 6;
            this.picBoxDiff.TabStop = false;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(9, 78);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(45, 13);
            this.label1.TabIndex = 5;
            this.label1.Text = "Console";
            // 
            // bnt_clearbump
            // 
            this.bnt_clearbump.AllowDrop = true;
            this.bnt_clearbump.Location = new System.Drawing.Point(76, 48);
            this.bnt_clearbump.Name = "bnt_clearbump";
            this.bnt_clearbump.Size = new System.Drawing.Size(47, 23);
            this.bnt_clearbump.TabIndex = 0;
            this.bnt_clearbump.Text = "Clear!";
            this.bnt_clearbump.UseVisualStyleBackColor = true;
            // 
            // bnt_cleardiffuse
            // 
            this.bnt_cleardiffuse.Location = new System.Drawing.Point(76, 48);
            this.bnt_cleardiffuse.Name = "bnt_cleardiffuse";
            this.bnt_cleardiffuse.Size = new System.Drawing.Size(47, 23);
            this.bnt_cleardiffuse.TabIndex = 2;
            this.bnt_cleardiffuse.Text = "Clear!";
            this.bnt_cleardiffuse.UseVisualStyleBackColor = true;
            // 
            // btn_relativ
            // 
            this.btn_relativ.Location = new System.Drawing.Point(168, 11);
            this.btn_relativ.Name = "btn_relativ";
            this.btn_relativ.Size = new System.Drawing.Size(104, 61);
            this.btn_relativ.TabIndex = 6;
            this.btn_relativ.TabStop = false;
            this.btn_relativ.Text = "relative path";
            this.btn_relativ.UseVisualStyleBackColor = true;
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.picBoxDiff);
            this.groupBox1.Controls.Add(this.btn_diffusemap);
            this.groupBox1.Controls.Add(this.bnt_cleardiffuse);
            this.groupBox1.Location = new System.Drawing.Point(6, 19);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(241, 100);
            this.groupBox1.TabIndex = 7;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Diffusemap";
            // 
            // groupBox2
            // 
            this.groupBox2.Controls.Add(this.picBoxBump);
            this.groupBox2.Controls.Add(this.btn_bumpmap);
            this.groupBox2.Controls.Add(this.bnt_clearbump);
            this.groupBox2.Location = new System.Drawing.Point(6, 125);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Size = new System.Drawing.Size(241, 100);
            this.groupBox2.TabIndex = 7;
            this.groupBox2.TabStop = false;
            this.groupBox2.Text = "Bumpmap";
            // 
            // picBoxBump
            // 
            this.picBoxBump.Location = new System.Drawing.Point(6, 19);
            this.picBoxBump.Name = "picBoxBump";
            this.picBoxBump.Size = new System.Drawing.Size(64, 64);
            this.picBoxBump.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picBoxBump.TabIndex = 6;
            this.picBoxBump.TabStop = false;
            // 
            // groupBox_Textures2
            // 
            this.groupBox_Textures2.Controls.Add(this.groupBox1);
            this.groupBox_Textures2.Controls.Add(this.groupBox2);
            this.groupBox_Textures2.Enabled = false;
            this.groupBox_Textures2.Location = new System.Drawing.Point(12, 220);
            this.groupBox_Textures2.Name = "groupBox_Textures2";
            this.groupBox_Textures2.Size = new System.Drawing.Size(260, 238);
            this.groupBox_Textures2.TabIndex = 7;
            this.groupBox_Textures2.TabStop = false;
            this.groupBox_Textures2.Text = "Textures";
            // 
            // groupBox3
            // 
            this.groupBox3.Controls.Add(this.picBoxTrans);
            this.groupBox3.Controls.Add(this.btn_transparentmap);
            this.groupBox3.Controls.Add(this.bnt_cleartransparent);
            this.groupBox3.Location = new System.Drawing.Point(12, 19);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(241, 100);
            this.groupBox3.TabIndex = 7;
            this.groupBox3.TabStop = false;
            this.groupBox3.Text = "Transparent";
            // 
            // picBoxTrans
            // 
            this.picBoxTrans.Location = new System.Drawing.Point(6, 19);
            this.picBoxTrans.Name = "picBoxTrans";
            this.picBoxTrans.Size = new System.Drawing.Size(64, 64);
            this.picBoxTrans.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picBoxTrans.TabIndex = 6;
            this.picBoxTrans.TabStop = false;
            // 
            // btn_transparentmap
            // 
            this.btn_transparentmap.AllowDrop = true;
            this.btn_transparentmap.Location = new System.Drawing.Point(76, 19);
            this.btn_transparentmap.Name = "btn_transparentmap";
            this.btn_transparentmap.Size = new System.Drawing.Size(143, 23);
            this.btn_transparentmap.TabIndex = 4;
            this.btn_transparentmap.Text = "drop transparentmap here";
            this.btn_transparentmap.UseVisualStyleBackColor = true;
            this.btn_transparentmap.DragDrop += new System.Windows.Forms.DragEventHandler(this.btn_transparentmap_DragDrop);
            this.btn_transparentmap.DragEnter += new System.Windows.Forms.DragEventHandler(this.btn_transparentmap_DragEnter);
            // 
            // bnt_cleartransparent
            // 
            this.bnt_cleartransparent.Location = new System.Drawing.Point(77, 48);
            this.bnt_cleartransparent.Name = "bnt_cleartransparent";
            this.bnt_cleartransparent.Size = new System.Drawing.Size(46, 23);
            this.bnt_cleartransparent.TabIndex = 4;
            this.bnt_cleartransparent.Text = "Clear!";
            this.bnt_cleartransparent.UseVisualStyleBackColor = true;
            // 
            // groupBox4
            // 
            this.groupBox4.Controls.Add(this.picBoxSpec);
            this.groupBox4.Controls.Add(this.btn_specularmap);
            this.groupBox4.Controls.Add(this.btn_clearspec);
            this.groupBox4.Location = new System.Drawing.Point(12, 125);
            this.groupBox4.Name = "groupBox4";
            this.groupBox4.Size = new System.Drawing.Size(241, 100);
            this.groupBox4.TabIndex = 7;
            this.groupBox4.TabStop = false;
            this.groupBox4.Text = "Specular";
            // 
            // picBoxSpec
            // 
            this.picBoxSpec.Location = new System.Drawing.Point(6, 19);
            this.picBoxSpec.Name = "picBoxSpec";
            this.picBoxSpec.Size = new System.Drawing.Size(64, 64);
            this.picBoxSpec.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picBoxSpec.TabIndex = 6;
            this.picBoxSpec.TabStop = false;
            // 
            // btn_specularmap
            // 
            this.btn_specularmap.AllowDrop = true;
            this.btn_specularmap.Location = new System.Drawing.Point(76, 19);
            this.btn_specularmap.Name = "btn_specularmap";
            this.btn_specularmap.Size = new System.Drawing.Size(143, 23);
            this.btn_specularmap.TabIndex = 3;
            this.btn_specularmap.Text = "drop the specularmap here";
            this.btn_specularmap.UseVisualStyleBackColor = true;
            this.btn_specularmap.DragDrop += new System.Windows.Forms.DragEventHandler(this.btn_specularmap_DragDrop);
            this.btn_specularmap.DragEnter += new System.Windows.Forms.DragEventHandler(this.btn_specularmap_DragEnter);
            // 
            // btn_clearspec
            // 
            this.btn_clearspec.Location = new System.Drawing.Point(76, 48);
            this.btn_clearspec.Name = "btn_clearspec";
            this.btn_clearspec.Size = new System.Drawing.Size(46, 23);
            this.btn_clearspec.TabIndex = 3;
            this.btn_clearspec.Text = "Clear!";
            this.btn_clearspec.UseVisualStyleBackColor = true;
            // 
            // groupBox5
            // 
            this.groupBox5.Controls.Add(this.picBoxAmbient);
            this.groupBox5.Controls.Add(this.btn_ambientmap);
            this.groupBox5.Controls.Add(this.btn_clearambient);
            this.groupBox5.Location = new System.Drawing.Point(12, 231);
            this.groupBox5.Name = "groupBox5";
            this.groupBox5.Size = new System.Drawing.Size(241, 100);
            this.groupBox5.TabIndex = 7;
            this.groupBox5.TabStop = false;
            this.groupBox5.Text = "Ambient";
            // 
            // picBoxAmbient
            // 
            this.picBoxAmbient.Location = new System.Drawing.Point(6, 19);
            this.picBoxAmbient.Name = "picBoxAmbient";
            this.picBoxAmbient.Size = new System.Drawing.Size(64, 64);
            this.picBoxAmbient.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picBoxAmbient.TabIndex = 6;
            this.picBoxAmbient.TabStop = false;
            // 
            // btn_ambientmap
            // 
            this.btn_ambientmap.AllowDrop = true;
            this.btn_ambientmap.Location = new System.Drawing.Point(77, 19);
            this.btn_ambientmap.Name = "btn_ambientmap";
            this.btn_ambientmap.Size = new System.Drawing.Size(143, 23);
            this.btn_ambientmap.TabIndex = 3;
            this.btn_ambientmap.Text = "drop the ambientmap here";
            this.btn_ambientmap.UseVisualStyleBackColor = true;
            this.btn_ambientmap.DragDrop += new System.Windows.Forms.DragEventHandler(this.btn_ambientmap_DragDrop);
            this.btn_ambientmap.DragEnter += new System.Windows.Forms.DragEventHandler(this.btn_ambientmap_DragEnter);
            // 
            // btn_clearambient
            // 
            this.btn_clearambient.Location = new System.Drawing.Point(77, 48);
            this.btn_clearambient.Name = "btn_clearambient";
            this.btn_clearambient.Size = new System.Drawing.Size(46, 23);
            this.btn_clearambient.TabIndex = 3;
            this.btn_clearambient.Text = "Clear!";
            this.btn_clearambient.UseVisualStyleBackColor = true;
            // 
            // groupBox6
            // 
            this.groupBox6.Controls.Add(this.picBoxReflec);
            this.groupBox6.Controls.Add(this.btn_reflectivemap);
            this.groupBox6.Controls.Add(this.btn_clreareflective);
            this.groupBox6.Location = new System.Drawing.Point(12, 337);
            this.groupBox6.Name = "groupBox6";
            this.groupBox6.Size = new System.Drawing.Size(241, 100);
            this.groupBox6.TabIndex = 7;
            this.groupBox6.TabStop = false;
            this.groupBox6.Text = "Reflective";
            // 
            // picBoxReflec
            // 
            this.picBoxReflec.Location = new System.Drawing.Point(6, 19);
            this.picBoxReflec.Name = "picBoxReflec";
            this.picBoxReflec.Size = new System.Drawing.Size(64, 64);
            this.picBoxReflec.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picBoxReflec.TabIndex = 6;
            this.picBoxReflec.TabStop = false;
            // 
            // btn_reflectivemap
            // 
            this.btn_reflectivemap.AllowDrop = true;
            this.btn_reflectivemap.Location = new System.Drawing.Point(76, 19);
            this.btn_reflectivemap.Name = "btn_reflectivemap";
            this.btn_reflectivemap.Size = new System.Drawing.Size(143, 23);
            this.btn_reflectivemap.TabIndex = 3;
            this.btn_reflectivemap.Text = "drop the reflectivemap here";
            this.btn_reflectivemap.UseVisualStyleBackColor = true;
            this.btn_reflectivemap.DragDrop += new System.Windows.Forms.DragEventHandler(this.btn_reflectivemap_DragDrop);
            this.btn_reflectivemap.DragEnter += new System.Windows.Forms.DragEventHandler(this.btn_reflectivemap_DragEnter);
            // 
            // btn_clreareflective
            // 
            this.btn_clreareflective.Location = new System.Drawing.Point(77, 48);
            this.btn_clreareflective.Name = "btn_clreareflective";
            this.btn_clreareflective.Size = new System.Drawing.Size(46, 23);
            this.btn_clreareflective.TabIndex = 3;
            this.btn_clreareflective.Text = "Clear!";
            this.btn_clreareflective.UseVisualStyleBackColor = true;
            // 
            // groupBox_Textures
            // 
            this.groupBox_Textures.Controls.Add(this.groupBox6);
            this.groupBox_Textures.Controls.Add(this.groupBox5);
            this.groupBox_Textures.Controls.Add(this.groupBox4);
            this.groupBox_Textures.Controls.Add(this.groupBox3);
            this.groupBox_Textures.Enabled = false;
            this.groupBox_Textures.Location = new System.Drawing.Point(278, 11);
            this.groupBox_Textures.Name = "groupBox_Textures";
            this.groupBox_Textures.Size = new System.Drawing.Size(259, 447);
            this.groupBox_Textures.TabIndex = 5;
            this.groupBox_Textures.TabStop = false;
            this.groupBox_Textures.Text = "Textures";
            // 
            // Form1
            // 
            this.AllowDrop = true;
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(549, 465);
            this.Controls.Add(this.groupBox_Textures2);
            this.Controls.Add(this.btn_relativ);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.richTextBox1);
            this.Controls.Add(this.groupBox_Textures);
            this.Controls.Add(this.btn_dae);
            this.MaximizeBox = false;
            this.Name = "Form1";
            this.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide;
            this.Text = "set Bumpmap";
            this.Load += new System.EventHandler(this.Form1_Load);
            ((System.ComponentModel.ISupportInitialize)(this.picBoxDiff)).EndInit();
            this.groupBox1.ResumeLayout(false);
            this.groupBox2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.picBoxBump)).EndInit();
            this.groupBox_Textures2.ResumeLayout(false);
            this.groupBox3.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.picBoxTrans)).EndInit();
            this.groupBox4.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.picBoxSpec)).EndInit();
            this.groupBox5.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.picBoxAmbient)).EndInit();
            this.groupBox6.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.picBoxReflec)).EndInit();
            this.groupBox_Textures.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btn_dae;
        private System.Windows.Forms.Button btn_bumpmap;
        private System.Windows.Forms.RichTextBox richTextBox1;
        private System.Windows.Forms.Button btn_diffusemap;
        private System.Windows.Forms.Button btn_relativ;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Button bnt_clearbump;
        private System.Windows.Forms.Button bnt_cleardiffuse;
        private System.Windows.Forms.PictureBox picBoxDiff;
        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.GroupBox groupBox2;
        private System.Windows.Forms.PictureBox picBoxBump;
        private System.Windows.Forms.GroupBox groupBox_Textures2;
        private System.Windows.Forms.GroupBox groupBox3;
        private System.Windows.Forms.PictureBox picBoxTrans;
        private System.Windows.Forms.Button btn_transparentmap;
        private System.Windows.Forms.Button bnt_cleartransparent;
        private System.Windows.Forms.GroupBox groupBox4;
        private System.Windows.Forms.PictureBox picBoxSpec;
        private System.Windows.Forms.Button btn_specularmap;
        private System.Windows.Forms.Button btn_clearspec;
        private System.Windows.Forms.GroupBox groupBox5;
        private System.Windows.Forms.PictureBox picBoxAmbient;
        private System.Windows.Forms.Button btn_ambientmap;
        private System.Windows.Forms.Button btn_clearambient;
        private System.Windows.Forms.GroupBox groupBox6;
        private System.Windows.Forms.PictureBox picBoxReflec;
        private System.Windows.Forms.Button btn_reflectivemap;
        private System.Windows.Forms.Button btn_clreareflective;
        private System.Windows.Forms.GroupBox groupBox_Textures;
    }
}

