import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:appliances_flutter/common/app_style.dart';
import 'package:appliances_flutter/common/reusable_text.dart';
import 'package:appliances_flutter/constants/constants.dart';

class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  Widget _section(String title, String body) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReusableText(
              text: title, style: appStyle(14, kDark, FontWeight.w700)),
          SizedBox(height: 6.h),
          Text(
            body,
            style: appStyle(12, kGray, FontWeight.w400),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính sách & Điều khoản'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          _section(
            'Giới thiệu',
            'Chào mừng bạn đến với ứng dụng của chúng tôi. Việc sử dụng ứng dụng đồng nghĩa với việc bạn đã đọc, hiểu và đồng ý với các điều khoản và chính sách dưới đây.',
          ),
          _section(
            'Thu thập thông tin',
            'Chúng tôi có thể thu thập thông tin bạn cung cấp trực tiếp (ví dụ: tên, số điện thoại, ảnh cửa hàng) và thông tin phát sinh trong quá trình sử dụng (ví dụ: địa chỉ, toạ độ).',
          ),
          _section(
            'Mục đích sử dụng',
            'Thông tin được sử dụng để cung cấp và cải thiện dịch vụ, hỗ trợ xác thực, hiển thị cửa hàng tới người dùng và đảm bảo an toàn tài khoản.',
          ),
          _section(
            'Chia sẻ thông tin',
            'Chúng tôi không bán dữ liệu cá nhân. Một số thông tin có thể được chia sẻ với đối tác phục vụ vận hành hệ thống (ví dụ: dịch vụ lưu trữ hình ảnh) theo thỏa thuận bảo mật.',
          ),
          _section(
            'Bảo mật',
            'Chúng tôi áp dụng các biện pháp phù hợp để bảo vệ dữ liệu. Tuy nhiên, không có hệ thống nào an toàn tuyệt đối. Bạn cần bảo mật thông tin đăng nhập của mình.',
          ),
          _section(
            'Quyền của bạn',
            'Bạn có quyền xem, cập nhật hoặc yêu cầu xoá thông tin cá nhân theo quy định pháp luật hiện hành. Vui lòng liên hệ bộ phận hỗ trợ khi cần.',
          ),
          _section(
            'Nội dung & Hình ảnh',
            'Bạn chịu trách nhiệm về nội dung/hình ảnh tải lên. Không được đăng tải nội dung vi phạm pháp luật, bản quyền hoặc chuẩn mực cộng đồng.',
          ),
          _section(
            'Điều khoản sử dụng',
            'Không lạm dụng tính năng, không can thiệp trái phép vào hệ thống. Vi phạm có thể dẫn đến tạm khoá hoặc chấm dứt tài khoản.',
          ),
          _section(
            'Cập nhật chính sách',
            'Chính sách có thể được cập nhật định kỳ. Các thay đổi sẽ có hiệu lực kể từ khi công bố trong ứng dụng.',
          ),
          _section(
            'Liên hệ',
            'Nếu có câu hỏi về chính sách, vui lòng liên hệ bộ phận hỗ trợ trong ứng dụng hoặc email hỗ trợ đã công bố.',
          ),
          SizedBox(height: 8.h),
          Text(
            'Lưu ý: Tài liệu này mang tính mô phỏng cho mục đích minh hoạ giao diện.',
            style: appStyle(11, kGray, FontWeight.w400),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Đã hiểu'),
            ),
          )
        ],
      ),
    );
  }
}
