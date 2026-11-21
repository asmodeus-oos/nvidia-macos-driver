; A byte-array init loop compared against its end pointer, with both GEPs rooted at the same
; alloca. Metal emits this shape for an aggregate field initialised to `undefined`/zeroed
; (e.g. Horizon's TerrainOut byte arrays) and only the raw byte-offset path can express the
; compare, since the walker's index is dynamic.
; The driver used to answer "pointer icmp is only supported against null: eq ptr %next, %end"
; because the alloca arrived at that path under two names: %in and its no-op bitcast %0.
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-n8:16:32"
target triple = "air64_v28-apple-macosx26.7.0"

%struct.Out = type { <4 x float>, [4 x i8] }

define <{ <4 x float> }> @fs_byte_array_init(<4 x float> %clip) {
entry:
  %out = alloca %struct.Out, align 16
  %0 = bitcast ptr %out to ptr
  call void @llvm.lifetime.start.p0(i64 20, ptr nonnull %0)
  %begin = getelementptr inbounds %struct.Out, ptr %out, i64 0, i32 1, i64 0
  %end = getelementptr inbounds %struct.Out, ptr %out, i64 0, i32 1, i64 4
  br label %body

body:                                             ; preds = %body, %entry
  %cur = phi ptr [ %begin, %entry ], [ %next, %body ]
  store i8 0, ptr %cur, align 1
  %next = getelementptr inbounds i8, ptr %cur, i64 1
  %done = icmp eq ptr %next, %end
  br i1 %done, label %exit, label %body

exit:                                             ; preds = %body
  ret <{ <4 x float> }> zeroinitializer
}

declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none))
