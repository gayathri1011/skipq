import bcrypt from 'bcryptjs';
import Student from '../models/Student.js';
import Manager from '../models/Manager.js';
import { signToken } from '../config/jwt.js';

const MOBILE_REGEX = /^[6-9]\d{9}$/;
const NAME_REGEX = /^[A-Za-z ]+$/;

const buildStudentResponse = (student, token) => ({
  success: true,
  data: {
    token,
    user: {
      id: student._id,
      role: 'student',
      name: student.name,
      mobile: student.mobile,
      registerNumber: student.registerNumber ?? '',
      department: student.department ?? '',
      academicStream: student.academicStream ?? '',
    },
  },
});

const buildManagerResponse = (manager, token) => ({
  success: true,
  data: {
    token,
    user: {
      id: manager._id,
      role: 'manager',
      name: manager.name,
      managerId: manager.managerId,
    },
  },
});

const validateMobile = (mobile) => {
  const normalizedMobile = mobile?.trim();

  if (!normalizedMobile || !MOBILE_REGEX.test(normalizedMobile)) {
    return {
      error:
        'Mobile number must be exactly 10 digits and start with 6, 7, 8, or 9',
    };
  }

  return { value: normalizedMobile };
};

const validateName = (name) => {
  const normalizedName = name?.trim();

  if (!normalizedName) {
    return { error: 'Name is required' };
  }

  if (normalizedName.length < 2 || !NAME_REGEX.test(normalizedName)) {
    return {
      error:
        'Name must be at least 2 characters and contain only letters and spaces',
    };
  }

  return { value: normalizedName };
};

export const studentRegister = async (req, res) => {
  try {
    const { name, mobile } = req.body;

    const nameResult = validateName(name);
    if (nameResult.error) {
      return res.status(400).json({ success: false, message: nameResult.error });
    }

    const mobileResult = validateMobile(mobile);
    if (mobileResult.error) {
      return res.status(400).json({
        success: false,
        message: mobileResult.error,
      });
    }

    const existing = await Student.findOne({ mobile: mobileResult.value });
    if (existing) {
      return res.status(409).json({
        success: false,
        message:
          'This number is already registered. Please use Login instead.',
      });
    }

    const student = await Student.create({
      name: nameResult.value,
      mobile: mobileResult.value,
    });

    const token = signToken({
      id: student._id.toString(),
      role: 'student',
      name: student.name,
      mobile: student.mobile,
    });

    return res.status(201).json(buildStudentResponse(student, token));
  } catch (error) {
    console.error('Student register error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to complete registration',
    });
  }
};

export const studentLogin = async (req, res) => {
  try {
    const { mobile } = req.body;

    const mobileResult = validateMobile(mobile);
    if (mobileResult.error) {
      return res.status(400).json({
        success: false,
        message: mobileResult.error,
      });
    }

    const student = await Student.findOne({ mobile: mobileResult.value });

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'No account found with this number. Please Register first.',
      });
    }

    const token = signToken({
      id: student._id.toString(),
      role: 'student',
      name: student.name,
      mobile: student.mobile,
    });

    return res.json(buildStudentResponse(student, token));
  } catch (error) {
    console.error('Student login error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to complete student login',
    });
  }
};

export const managerLogin = async (req, res) => {
  try {
    const { managerId, password } = req.body;

    if (!managerId?.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Manager ID is required',
      });
    }

    if (!password) {
      return res.status(400).json({
        success: false,
        message: 'Password is required',
      });
    }

    const manager = await Manager.findOne({
      managerId: managerId.trim().toUpperCase(),
    });

    if (!manager) {
      return res.status(401).json({
        success: false,
        message: 'Invalid Manager ID or password',
      });
    }

    const isMatch = await bcrypt.compare(password, manager.passwordHash);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid Manager ID or password',
      });
    }

    const token = signToken({
      id: manager._id.toString(),
      role: 'manager',
      name: manager.name,
      managerId: manager.managerId,
    });

    return res.json(buildManagerResponse(manager, token));
  } catch (error) {
    console.error('Manager login error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to complete manager login',
    });
  }
};

export const getMe = async (req, res) => {
  try {
    const { id, role } = req.user;

    if (role === 'student') {
      const student = await Student.findById(id).select(
        'name mobile registerNumber department academicStream createdAt',
      );

      if (!student) {
        return res.status(404).json({
          success: false,
          message: 'Student account not found',
        });
      }

      return res.json({
        success: true,
        data: {
          user: {
            id: student._id,
            role: 'student',
            name: student.name,
            mobile: student.mobile,
            registerNumber: student.registerNumber ?? '',
            department: student.department ?? '',
            academicStream: student.academicStream ?? '',
          },
        },
      });
    }

    if (role === 'manager') {
      const manager = await Manager.findById(id).select('managerId name');

      if (!manager) {
        return res.status(404).json({
          success: false,
          message: 'Manager account not found',
        });
      }

      return res.json({
        success: true,
        data: {
          user: {
            id: manager._id,
            role: 'manager',
            name: manager.name,
            managerId: manager.managerId,
          },
        },
      });
    }

    return res.status(403).json({
      success: false,
      message: 'Unknown role',
    });
  } catch (error) {
    console.error('Get me error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch user profile',
    });
  }
};

export const updateStudentProfile = async (req, res) => {
  try {
    const fields = ['name', 'registerNumber', 'department', 'academicStream'];
    const updates = Object.fromEntries(
      fields.map((field) => [field, String(req.body[field] ?? '').trim()]),
    );
    const student = await Student.findByIdAndUpdate(req.user.id, updates, {
      new: true,
      runValidators: true,
    });

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student account not found',
      });
    }

    return res.json({
      success: true,
      data: {
        user: {
          id: student._id,
          role: 'student',
          name: student.name,
          mobile: student.mobile,
          registerNumber: student.registerNumber ?? '',
          department: student.department ?? '',
          academicStream: student.academicStream ?? '',
        },
      },
    });
  } catch (error) {
    console.error('Update student profile error:', error.message);
    return res.status(400).json({
      success: false,
      message: 'Unable to update student profile',
    });
  }
};
